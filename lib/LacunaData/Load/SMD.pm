package LacunaData::Load::SMD;
use strict;
use warnings;
use autodie;

use LacunaData::Sources (
  id => ['smd'],
  qw(
    source_file
    get_source_from_file
    get_source_from_url
  )
);

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
  if( -e source_file ){
    return decode_json  get_source_from_file;
  }else{
    return _clean_up    get_source_from_url;
  }
}

sub Cache{
  # cache a cleaned up copy
  my $clean = _clean_up get_source_from_url;
  
  open my $fh, '>', source_file;
  print {$fh} $clean;
  close $fh;
  
  # return the data structure unless called in void context
  if( defined wantarray ){
    return decode_json $clean;
  }
}
1;
