package LacunaData::SMD;
use strict;
use warnings;
use autodie;

use LacunaData::Sources;
use JSON;

sub _clean_up{
  my($js) = @_;
  # skip if it is actually json
  unless( $js =~ /^\s*{/s ){
    $js =~ s/^.*?var smd = {/{/s;
    $js =~ s/};.*/}/s;
    $js =~ s(^\s*/\*.*?\*/){}smg;
    $js =~ s(\s*//.*){}mg;
    $js =~ s/^\t//mg;
    $js =~ s/^(\s*)(\w+)(\s*:\s*{)/$1"$2"$3/mg;
    $js =~ s/\s+$//mg;
  }
  return $js
}

{
  # cache a cleaned up copy
  my $source_uri  = LacunaData::Sources->source_of('smd');
  my $source_file = LacunaData::Sources->file_for('smd');
  unless( $source_file eq $source_uri ){
    my $raw = LacunaData::Sources->get_source('smd','url');
    open my $fh, '>', $source_file;
    print {$fh} _clean_up $raw;
    close $fh;
  }
}
our $data;
{
  my $source = LacunaData::Sources->get_source('smd');
  $data = decode_json $source;
  bless $data, __PACKAGE__;
}


sub object{
  return $data;
}

