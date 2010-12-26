package LacunaData::Sources;
use strict;
use warnings;
use autodie;
use 5.12.2;

use YAML qw'LoadFile';
use File::Spec::Functions qw'splitpath rel2abs catfile catpath';

require Exporter;
our @ISA = qw'Exporter';
our @EXPORT_OK = qw'source_of';

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
1
