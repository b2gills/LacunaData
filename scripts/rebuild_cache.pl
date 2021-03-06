#! /usr/bin/env perl
use strict;
use warnings;
use 5.12.2;
BEGIN {
  if ( $] >= 5.020_000 ){
    require experimental;
    experimental->import('smartmatch');
  }
}
use autodie;

use File::Spec::Functions qw'catdir';

use FindBin;
use lib "${FindBin::Bin}/../lib";

our $dir = "${FindBin::Bin}/../lib";
our @modules;

opendir my($dh), catdir($dir,'LacunaData','Load');

while( readdir $dh ){
  next unless s/\.pm$//;
  my $module =  "LacunaData::Load::$_";
  if( @ARGV && not $_ ~~ @ARGV ){
    say STDERR 'Skipping ', $module;
    next;
  }
  say STDERR 'Loading ', $module;
  if( eval "require $module" ){
    if( $module->can('Cache')){
      $module->Cache;
    }
  }
  print STDERR $@ if $@;
}
