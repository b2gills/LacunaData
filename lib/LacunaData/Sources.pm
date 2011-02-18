package LacunaData::Sources;
use strict;
use warnings;
use autodie;
use 5.12.2;

use YAML qw'LoadFile';
use File::Spec::Functions qw'splitpath rel2abs catfile catpath';

sub _generator{
  my($arg) = @_;
  my $ref = \&{$arg->{name}};
  
  my($id) = $arg->{arg}{id} || @{$arg->{col}{id}};
  if( $id ){
    return sub{ $ref->($id) };
  }else{
    return $ref;
  }
}

use Sub::Exporter -setup => {
  exports => [
    qw'source_file source source_url get_source get_source_from_url get_source_from_file'
  ],
  collectors => [ qw'id' ],
  generator => \&_generator,
};


our $global_config;
our $path;
BEGIN{
  my($vol,$dir, undef) = splitpath $INC{'LacunaData/Sources.pm'};
  $path = rel2abs catpath $vol, $dir;
  my $config_file = catfile $path, 'sources.yml';
  $global_config = LoadFile($config_file);
}

=head1 NAME

LacunaData::Sources

=head2 FUNCTIONS

=over 4

=item source

returns the name of the local file if it exists, the url otherwise

=cut

sub source{
  my($source) = @_;

  if( my $config = $global_config->{$source} ){
    if( $config->{file} ){
      my $file = rel2abs $config->{file}, $path;
      if( -e $file ){
        return $file;
      }
    }
    if( $config->{url} ){
      return $config->{url};
    }
  }

  my($package, $filename, $line) = caller;
  die qq[Unable to find the source of "$source" at $filename line:$line\n];
}
sub _source_from{
  my($source) = @_;

  if( my $config = $global_config->{$source} ){
    if( $config->{file} ){
      my $file = rel2abs $config->{file}, $path;
      if( -e $file ){
        return 'file';
      }
    }
    if( $config->{url} ){
      return 'url';
    }
  }

  my($package, $filename, $line) = caller;
  die qq[Unable to find the source of "$source" at $filename line:$line\n];
}

=item source_file

returns the name of the local file

=cut

sub source_file{
  my($source) = @_;

  my $file = rel2abs $global_config->{$source}{file}, $path;
  return $file if $file;

  my($package, $filename, $line) = caller;
  die qq[Unable to find the file for "$source" at $filename line:$line\n];
}

=item source_url

returns the url

=cut

sub source_url{
  my($source) = @_;

  my $url = $global_config->{$source}{url};
  return $url if $url;

  my($package, $filename, $line) = caller;
  die qq[Unable to find the url for "$source" at $filename line $line\n];
}

sub _read_file{
  my($filename) = @_;
  open my $fh, '<', $filename;
  local $/;
  my $contents = <$fh>;
  close $fh;
  return $contents;
}

=item get_source_from_file

returns the contents of the local storage file

=item get_source_from_url

returns the contents from the url

=cut

sub get_source_from_file{
  _read_file( source_file( $_[0] ) );
}
sub get_source_from_url{
  my $uri = source_url( $_[0] );
  
  if( $uri =~ m(^(?: https? | ftp ):// )x ){
    require LWP::Simple;
    my $return = LWP::Simple::get( $uri );
    die unless $return;
    return $return;
  }
  if( $uri =~ m(^file://(.*)) ){
    return _read_file($1);
  }
  die;
}

=item get_source

returns the entire contents of the local file if it exists,
otherwise it returns the contents from the url

=cut

sub get_source{
  my($source, $type) = @_;

  $type = _source_from($source) unless $type;

  if( $type eq 'file' ){
    return get_source_from_file($source);
  }elsif( $type eq 'url' ){
    return get_source_from_url($source);
  }else{
    my($package, $filename, $line) = caller;
    die "Invalid type $type at $filename line $line\n";
  }
}
1
