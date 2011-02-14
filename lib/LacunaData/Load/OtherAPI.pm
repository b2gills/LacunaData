package LacunaData::Load::OtherAPI;
use strict;
use warnings;
use 5.12.2;
use autodie;

use YAML qw'freeze thaw';

use HTML::TreeBuilder;

use LacunaData::Sources (
  id => ['other-api'],
  qw(
    source_file
    source_url
    get_source_from_file
  )
);
use LacunaData::Load::API::HTML;

use namespace::clean;

sub Load{
  if( -e source_file ){
    return thaw( get_source_from_file );
  }else{
    return _load();
  }
}

no namespace::clean;

sub _load{
  my $listing = _get_api_listing();
  my %building_data;
  
  use List::Util 'max';
  my $length = max map { length } keys %$listing;

  while( my($building,$url) = each %$listing ){
    my $pad = ' ' x ($length - length $building);
    print STDERR 'processing ', $building, $pad, "\r";
    
    my $parser = LacunaData::Load::API::HTML->new($url);
    my($services,$api_url,$desc) = $parser->method_data;
    
    my %data;
    $data{services} = $services if %$services;
    $data{'api-url'} = $api_url if $api_url;
    $data{description} = $desc if $desc;
    
    $building_data{$building} = \%data;
  }
  print STDERR ' ' x ($length+11), "\r";

  return \%building_data;
}

use namespace::clean;

sub Cache{
  my $data = _load();

  open my $fh, '>', source_file;
  print {$fh} freeze($data);
  close $fh;
  
  return $data;
}

sub base_url{
  my $base_url = source_url;
  $base_url =~ s(:// [^/]+ \K .*){}x;
  return $base_url;
}

no namespace::clean;

sub _get_api_listing{
  my %urls = map{
    $_, base_url()."/api/$_.html"
  } qw'Empire Alliance Inbox Body Stats Map';

  return \%urls;
}
1;
