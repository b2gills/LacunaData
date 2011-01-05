package LacunaData::Load::Glyph;
use strict;
use warnings;
use autodie;

use LacunaData::Sources (
  id => ['glyph-data'],
  qw(
    source_file
    source_url
    get_source_from_file
    get_source_from_url
  )
);

use LacunaData::Resources 'ore_list';
use HTML::TreeBuilder;
use YAML qw'thaw';
use LWP::Simple;
use List::Util qw'max';
use 5.12.2;

sub Load{
  if( -e source_file ){
    return thaw get_source_from_file;
  }else{
    return _load();
  }
}

sub _load{
  my $data = _load_list();
  
  my $length = max map { length } keys %$data;
  
  for my $building ( keys %$data ){
    my $pad = ' ' x ($length - length $building);
    print STDERR 'processing ', $building, $pad, "\r";
    _load_building($data,$building);
  }
  print STDERR ' ' x ($length + 11), "\r";
  
  return $data;
}

sub Cache{
  my $data = _load();
  
  use YAML 'DumpFile';
  DumpFile( source_file, $data );
  
  return $data;
}

{
  my @ore_list = ore_list;
  sub _only_png{
    my $alt = lc $_->attr('alt');
    return unless $alt;
    return unless $alt =~ /(.*)\.png/;
    $alt = $1;
    return unless $alt ~~ @ore_list;
    return $alt;
  }
}

sub _load_building{
  my($data,$building) = @_;
 
  my $tree = HTML::TreeBuilder->new();
  {
    my $url = $data->{$building}{wiki};
    my $content = get($url);
    $tree->parse_content($content);
  }
  # <div id="wikipagecontent"><div>
  my($body) = $tree->look_down(
    '_tag',
    'div',
    sub{
      $_[0]->attr('id') &&
      $_[0]->attr('id') eq 'wikipagecontent'
  })->content_list;
  
  {
    my $desc = $body->find('p')->as_text;
    $desc =~ s/^\s+ //x;
    $desc =~ s/ \s+$//x;
    $data->{$building}{desc} = $desc;
  }
 
  # ignore anything that can't be a glyph
  my @glyphs = map _only_png, $body->find('img');
 
  if( @glyphs ){
    $data->{$building}{recipe} = \@glyphs;
  }else{
    # if the above didn't catch any recipe
    # then there must be more than one
   
    # each recipe can be found in it's own
    # <p>
    my @p = $body->find('p');
   
    # ignore any upto, and including, a line
    # that has the word recipe in it
    while( my $p = shift @p ){
      last if $p->as_text =~ /recipe/;
    }
   
    @p = map{[
      split /\W+/, $_->as_text
    ]} @p;
   
    # make it a hash instead of an array of arrays
    my %recipe;
    my $index ='A';
    $recipe{$index++} = $_ for @p;
   
    $data->{$building}{recipe} = \%recipe;
  }
}

sub _load_list{
  my %info;
  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content( get_source_from_url );
  
  source_url =~ m(^( \w+ :// [^/]+ ))x;
  my $uri_root = $1;

  my @tables = $tree->look_down('class','recipe_table');

  for my $table ( @tables ){
    my $recipe_type = lc $table->find('td')->as_text;
    $recipe_type =~ s/\s*recipes?\s*//i;
   
    my @list;
    for my $a ( $table->find('a') ){
      my $link = $a->attr('href');
      my $name = $a->as_text;
     
      if( substr($link,0,1) eq '/' ){
        $link = $uri_root.$link;
      }
      $info{$name} = {
        wiki => $link,
        type => $recipe_type,
      };
    }
  }
  return \%info;
}

1;
