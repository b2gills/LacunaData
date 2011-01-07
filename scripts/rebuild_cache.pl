#! /usr/bin/env perl
use strict;
use warnings;
use 5.12.2;
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
  say STDERR 'Loading ', $module;
  if( eval "require $module" ){
    if( $module->can('Cache')){
      $module->Cache;
    }
  }
  print STDERR $@ if $@;
}
