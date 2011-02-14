package LacunaData::Load::BuildingAPI;
use strict;
use warnings;
use 5.12.2;
use autodie;

use YAML qw'freeze thaw';

use HTML::TreeBuilder;

use LacunaData::Sources (
  id => ['building-api'],
  qw(
    source_file
    source_url
    get_source_from_url
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
  my @simple;

  my $common = LacunaData::Load::API::HTML->new(source_url)->method_data;
  
  use List::Util 'max';
  my $length = max map { length } keys %$listing;

  while( my($building,$url) = each %$listing ){
    my $pad = ' ' x ($length - length $building);
    print STDERR 'processing ', $building, $pad, "\r";
    
    my $parser = LacunaData::Load::API::HTML->new($url);
    my($services,$api_url,$desc) = $parser->method_data;
    
    my %data;
    $data{services} = $services if %$services;
    $data{description} = $desc if $desc;
    
    if( %data ){
      $building_data{$building} = \%data;
    }else{
      push @simple, $building;
    }
  }
  print STDERR ' ' x $length, "\r";

  _override(\%building_data,\@simple);
  push @simple, _missing( @simple, keys %building_data);
  @simple = sort @simple;

  $building_data{common} = $common;
  $building_data{simple} = \@simple;
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
  my %urls;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content( get_source_from_url );

  my @list = $tree->find('dl')->find('dt');
  for my $building ( @list ){
    my $name = $building->as_text;
    my(undef,$info_url) = $building->find('a');
    $info_url = base_url().$info_url->attr('href');
    $urls{$name} = $info_url;
  }

  return \%urls;
}

use LacunaData::Sources (
  id => ['building-api.missing'],
  source_file          => { -as => 'missing_file' },
  get_source_from_file => { -as => 'missing' },
);

sub _missing{
  my(@found) = @_;
  
  my @check = split '\n', missing;
  my @missing = grep{
    !($_ ~~ @found)
  } @check;

  if( @missing != @check ){
    open my $fh, '>', missing_file;
    say $fh $_ for sort @missing;
    close $fh;
  }
  return @missing if wantarray;
  return \@missing;
}

use LacunaData::Sources (
  id => ['building-api.override'],
  source_file          => { -as => 'override_file' },
  get_source_from_file => { -as => 'override' },
);

sub _override{
  my($data,$simple) = @_;
  my $override = thaw( override );
  
  while( my($key, $value) = each %$override ){
    if( defined $value ){
      $data->{$key} = $value;
      @$simple = grep{
        $_ ne $key
      } @$simple;
    }else{
      delete $data->{$key};
      push @$simple, $key;
    }
  }
}

1;
