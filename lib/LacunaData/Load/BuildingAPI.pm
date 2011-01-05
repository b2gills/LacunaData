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

sub Load{
  if( -e source_file ){
    return thaw( get_source_from_file );
  }else{
    return _load();
  }
}

sub _load{
  my $listing = _get_api_listing();
  my %building_data;

  my $common = _get_common_api_info();
  
  use List::Util 'max';
  my $length = max map { length } keys %$listing;

  while( my($building,$url) = each %$listing ){
    my $pad = ' ' x ($length - length $building);
    print STDERR 'processing ', $building, $pad, "\r";
    $building_data{$building} = _get_api_info($url);
  }
  print STDERR ' ' x $length, "\r";

  $building_data{common} = $common;
  return \%building_data;
}

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

sub _get_common_api_info{
  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content( get_source_from_url );

  my($method_head) = grep {
    $_->as_text eq 'Building Methods'
  } $tree->find('h1');

  return _get_api_method_info($method_head->right);
}

sub _get_api_info{
  my($url) = @_;

  my %data;

  my $tree = HTML::TreeBuilder->new();
  require LWP::Simple;
  my $content = LWP::Simple::get($url);
  die unless $content;
  $tree->parse_content($content);

  $data{'api-url'} = $tree->find('code')->as_text;

  my $head = $tree->find('h1');
  my(undef,@tail) = $head->right;
  pop @tail;

  while( @tail ){
    last unless $tail[0]->tag eq 'p';

    my $elem = shift @tail;
    my $text = $elem->as_text;

    unless( $text =~ /all buildings share./i ){
      $data{description} = $text;
    }
  }

  my $methods = _get_api_method_info(@tail);
  $data{methods} = $methods if $methods;

  return \%data;
}

sub _get_api_method_info{
  my @tail = @_;

  my %method;

  my $method;
  my $arg;
  for my $elem ( @tail ){
    my $tag  = $elem->tag;
    my $text = $elem->as_text;
    given( $tag ){
      when( 'h1' ){ last }
      when( 'h2' ){
        my($name,$args) = $text =~ /(\w+) \s* \(\s* (.*?) \s*\)/x;
        my @args = split ', ', $args;

        $method{$name}{'arg-order'} = \@args;

        $method = $name;
        undef $arg;
      }
      when( 'p' ){
        if( $arg and $method ){
          $method{$method}{'arg-info'}{$arg} = $text;
        }elsif( $method ){
          if( $text =~ /^throw\D*(.*)/i ){
            my @throws = sort {$a<=>$b} split /\D+/, $1;
            $method{$method}{throws} = \@throws;
          }else{
            no warnings 'uninitialized';
            $method{$method}{desc} .= $text;
          }
        }
      }
      when( 'h3' ){
        $arg = $text;
      }
    }
  }

  return \%method if %method;
  return;
}
1;
