#! /usr/bin/env perl
use strict;
use warnings;
use autodie;
use 5.10.1;

use DateTime;
use File::Spec::Functions qw'no_upwards catfile';

my $branch = 'data';
my $build = 'data';
my $message = 'Built on ' . DateTime->now->ymd;
my @skip = (
  qr'[.](?:override|missing)$',
  qw{
    error-code-id.yml
  },
);

print commit_build( $build, $branch, $message ),"\n";

sub verify_rev_list{
  my($git,$verify) = @_;
  eval{
    $git->rev_parse(
      { q => 1, verify => 1 }, $verify
    )
  }
}
sub commit_build {
  my ( $build_dir, $branch, $message ) = @_;

  return unless $branch and $message;

  require Cwd;
  require File::Spec;
  require File::Temp;
  require Git::Wrapper;

  our $CWD = Cwd::getcwd();

  my $tmp_dir = File::Temp->newdir( CLEANUP => 1 ) ;
  my $src     = Git::Wrapper->new('.');

  my $tree = do {
    # don't overwrite the user's index
    local $ENV{GIT_INDEX_FILE}
      = catfile( $tmp_dir, "temp_git_index" );

    local $ENV{GIT_DIR}
      = catfile( $CWD,     '.git' );

    local $ENV{GIT_WORK_TREE}
      = $build_dir;

    local $CWD = $build_dir;

    my $write_tree_repo = Git::Wrapper->new('.');

    my @files;
    {
      opendir my($dh), $ENV{GIT_WORK_TREE};
      @files = readdir $dh;
      closedir $dh;
    }
    @files = grep{
      not $_ ~~ @skip
    } no_upwards @files;

    $write_tree_repo->add({ v => 1, force => 1}, @files );
    ($write_tree_repo->write_tree)[0];
  };

  if(
    verify_rev_list($src,$branch)
    and $src->diff( { 'stat' => 1 }, $branch, '--', $tree )
  ){
    return 'No difference detected';
  }

  my @parents = grep {
    verify_rev_list($src,$_)
  } $branch, 'HEAD';

  my @commit;
  {
    # Git::Wrapper doesn't read from STDIN, which is
    # needed for commit-tree, so we have to everything
    # ourselves
    #
    my ($fh, $filename) = File::Temp::tempfile();
    $fh->autoflush(1);
    print {$fh} $message;
    $fh->close;

    my @args=('git', 'commit-tree', $tree, map { ( -p => $_ ) } @parents);
    push @args,'<'.$filename;
    my $cmdline=join(' ',@args);
    @commit=qx/$cmdline/;

    chomp(@commit);
  }

  $src->update_ref( 'refs/heads/' . $branch, $commit[0] );
  return "refs/heads/$branch $commit[0]";
}
