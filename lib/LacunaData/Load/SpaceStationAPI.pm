package LacunaData::Load::SpaceStationAPI;
use strict;
use warnings;
use 5.12.2;
use autodie;

use YAML qw'freeze thaw';

use HTML::TreeBuilder;

use LacunaData::Sources (
  id => ['space-station-api'],
  qw(
    source_file
    source_url
    get_source_from_url
    get_source_from_file
  )
);
use LacunaData::Load::API::HTML;

use namespace::clean;

=head1 NAME

LacunaData::Load::BuildingAPI

=head2 C<Load>

Returns information about the Lacuna Expanse API, excluding the buildings.

=cut

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
  my %station_data;
  my @simple;

  # common is the same as building api common
  # minus  build, upgrade, downgrade, demolish, and repair
  #my $common = LacunaData::Load::API::HTML->new(source_url)->method_data;

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
      $station_data{$building} = \%data;
    }else{
      push @simple, $building;
    }
  }
  print STDERR ' ' x (11 + $length), "\r";

  #_override(\%station_data,\@simple);
  #push @simple, _missing( @simple, keys %station_data);
  @simple = sort @simple;

  #$station_data{common} = $common;
  $station_data{simple} = \@simple;
  $station_data{common_minus} = _get_common_minus();
  return \%station_data;
}

use namespace::clean;

=head2 C<Cache>

Generate information about the Lacuna Expanse API, but only for the buildings

It does this by looking over the web pages for the API.

It then saves a copy of this data.

=cut

sub Cache{
  my $data = _load();

  open my $fh, '>', source_file;
  print {$fh} freeze($data);
  close $fh;

  return $data;
}

no namespace::clean;

sub base_url{
  my $base_url = source_url;
  $base_url =~ s(:// [^/]+ \K .*){}x;
  return $base_url;
}

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

  $tree->delete;

  return \%urls;
}

sub _get_common_minus{
  my @minus;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content( get_source_from_url );

  my @list = $tree->find('p');
  for my $p ( @list ){
    my $text = $p->as_text;
    if( $text =~ /^Modules can only/ ){
      @minus = sort map{
        $_->as_text
      } $p->find('code');
      last;
    }
  }

  $tree->delete;

  return \@minus;
}

#use LacunaData::Sources (
#  id => ['space-station-api.missing'],
#  source_file          => { -as => 'missing_file' },
#  get_source_from_file => { -as => 'missing' },
#);
#
#sub _missing{
#  my(@found) = @_;
#
#  # skip if the 'missing' file is not there
#  my $missing = eval{ missing } or return;
#  my @check = split '\n', $missing;
#  my @missing = grep{
#    !($_ ~~ @found)
#  } @check;
#
#  if( @missing != @check ){
#    open my $fh, '>', missing_file;
#    say $fh $_ for sort @missing;
#    close $fh;
#  }
#  return @missing if wantarray;
#  return \@missing;
#}
#
#use LacunaData::Sources (
#  id => ['space-station-api.override'],
#  source_file          => { -as => 'override_file' },
#  get_source_from_file => { -as => 'override' },
#);
#
#sub _override{
#  my($data,$simple) = @_;
#  my $override = thaw( override );
#
#  while( my($key, $value) = each %$override ){
#    if( defined $value ){
#      $data->{$key} = $value;
#      @$simple = grep{
#        $_ ne $key
#      } @$simple;
#    }else{
#      delete $data->{$key};
#      push @$simple, $key;
#    }
#  }
#}

use namespace::clean;

1;
