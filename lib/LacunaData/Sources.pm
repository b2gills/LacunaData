package LacunaData::Sources;
use strict;
use warnings;
use autodie;
use 5.12.2;

use YAML qw'LoadFile';
use File::Spec::Functions qw'splitpath rel2abs catfile catpath';
use LWP::Simple;

require Exporter;
our @ISA = qw'Exporter';
our @EXPORT_OK = qw'source_of url_for file_for get_source';

our $global_config;
our $path;
BEGIN{
  my($vol,$dir, undef) = splitpath $INC{'LacunaData/Sources.pm'};
  $path = rel2abs catpath $vol, $dir;
  my $config_file = catfile $path, 'sources.yml';
  $global_config = LoadFile($config_file);
}


sub source_of{
  my($class, $source) = @_;
  $source = $class unless $class eq __PACKAGE__;

  if( my $config = $global_config->{$source} ){
    if( $config->{file} ){
      my $file = rel2abs $config->{file}, $path;
      if( -e $file ){
        return $file;
      }
    }elsif( $config->{url} ){
      return $config->{url};
    }
  }

  my($package, $filename, $line) = caller;
  die qq[Unable to find the source of "$source" at $filename line:$line\n];
}

sub file_for{
  my($class, $source) = @_;
  $source = $class unless $class eq __PACKAGE__;

  my $file = rel2abs $global_config->{$source}{file}, $path;
  return $file if $file;

  my($package, $filename, $line) = caller;
  die qq[Unable to find the file for "$source" at $filename line:$line\n];
}

sub url_for{
  my($class, $source) = @_;
  $source = $class unless $class eq __PACKAGE__;

  my $url = $global_config->{$source}{url};
  return $url if $url;

  my($package, $filename, $line) = caller;
  die qq[Unable to find the url for "$source" at $filename line:$line\n];
}

sub _read_file{
  my($filename) = @_;
  open my $fh, '<', $filename;
  local $/;
  my $contents = <$fh>;
  close $fh;
  return $contents;
}

sub get_source{
  my $class = __PACKAGE__;
  shift if $_[0] eq $class;
  my($source, $type) = @_;

  my $uri;
  if( $type ){
    given( $type ){
      $uri = $class->url_for( $source) when 'url';
      $uri = $class->file_for($source) when 'file';
    }
  }else{
    $uri = $class->source_of($source);
  }

  given( $uri ){
    return get $uri when m(^(?: https? | ftp ):// )x;
    when( m(^file://(.*)) ){
      return _read_file($1);
    }
    default{
      return _read_file($uri);
    }
  }
}
1
