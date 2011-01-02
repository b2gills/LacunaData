package LacunaData::Load::SMD;
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

sub Load{
  my $source_uri  = LacunaData::Sources->source_of('smd');
  my $source_file = LacunaData::Sources->file_for('smd');
  my $source      = LacunaData::Sources->get_source('smd');
  if( $source_file ne $source_uri ){
    $source = _clean_up $source;
  }
  return decode_json $source;
}

sub Cache{
  # cache a cleaned up copy
  my $source_file = LacunaData::Sources->file_for('smd');
  my $raw = LacunaData::Sources->get_source('smd','url');
  my $clean = _clean_up($raw);
  
  open my $fh, '>', $source_file;
  print {$fh} $clean;
  close $fh;
  
  # return the data structure unless called in void context
  if( defined wantarray ){
    return decode_json $clean;
  }
}
1;
