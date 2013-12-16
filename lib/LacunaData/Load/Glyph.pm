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

use LacunaData::Resources qw'ore_list all_food_list normalize_food';
use HTML::TreeBuilder;
use YAML qw'thaw';
use List::Util qw'max';
use List::MoreUtils qw'uniq';
use 5.12.2;

use namespace::clean;

=head1 NAME

LacunaData::Load::Glyph

=head2 C<Load>

Returns the collected data for the Lacuna Expanse glyph buildings.

=cut

sub Load{
  if( -e source_file ){
    return thaw get_source_from_file;
  }else{
    return _load();
  }
}

no namespace::clean;

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

use namespace::clean;

=head2 C<Cache>

Generates data of glyph buildings from available sources,
and stores a local copy.

=cut

sub Cache{
  my $data = _load();

  use YAML 'DumpFile';
  DumpFile( source_file, $data );

  return $data;
}

no namespace::clean;

{
  my @ore_list = ore_list;
  sub _only_png{
    my $alt = $_->attr('alt');
    return unless $alt;
    $alt = lc $alt;
    return unless $alt =~ /(.*)\.png/;
    $alt = $1;
    return unless $alt ~~ @ore_list;
    return $alt;
  }
}
{
  my $food_match = eval 'qr{\b('.join('|', all_food_list).')\b}i';
  my $basic_match = qr{\b(?:food|ore|water|energy|happiness)\b};

  sub _add_produces{
    my($building,$data) = @_;
    $building = lc $building;

    my $desc = $data->{description} || '';

    if( my($food) = "$building $desc" =~ $food_match ){
      $data->{produces} = normalize_food($food);

    }elsif( my @resources = $desc =~ /$basic_match/g ){
      @resources = uniq sort @resources;
      $data->{produces} = \@resources;

    }

    return;
  }
}

sub _load_building{
  my($data,$building) = @_;

  my $tree = HTML::TreeBuilder->new();
  {
    my $url = $data->{$building}{wiki};
    require LWP::Simple;
    my $content = LWP::Simple::get( $url );
    die unless $content;
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
    my $desc_div = $body->find('div');
    my @p = grep { $_->tag eq 'p' } $desc_div->content_list;
    my @desc = grep { /\S/ } map {$_->as_text} @p;
    s/^\s+ //x, s/ \s+$//x for @desc;
    my $desc = join "\n",  @desc;

    my $data = $data->{$building};
    $data->{description} = $desc if $desc;

    # find any orbits listed
    if( $desc =~ /\b orbits? \s+ ( (?:[1-8] \s* (?: and \s+ )? )+  )/x ){
      my $orbits = $1;
      my @orbits = split /\s+(?:and\s*)?/, $orbits;
      if( @orbits ){
        $data->{orbits} = \@orbits;
      }
    }

    # check for text recipes
    my $ore_match = '(?:' . join('|',ore_list) . ')';
    if( $desc =~ /requires\b(\N*?)\bglyphs/i ){
      my @match = map{ lc $_ } $1 =~ /($ore_match)/xgi;
      $data->{recipe} = \@match if @match;
    }elsif( $desc =~ /(?:glyph recipe|combining)(\N*)/i ){
      my @match = map{ lc $_ } $1 =~ /($ore_match)/xgi;
      $data->{recipe} = \@match if @match;
    }elsif( $desc =~ /($ore_match\b.*\b$ore_match)/i ){
      my @match = map{ lc $_ } $1 =~ /($ore_match)/xgi;
      $data->{recipe} = \@match if @match;
    }

    unless( $building eq 'Black Hole Generator' ){
    _add_produces($building,$data);
    }
  }

  unless( $data->{$building}{recipe} ){
    # ignore anything that can't be a glyph
    my @glyphs = map _only_png, $body->find('img');

    if( @glyphs ){
      $data->{$building}{recipe} = \@glyphs;
    }else{
      # if the above didn't catch any recipe
      # then there must be more than one

      # each recipe can be found in it's own
      # <li>
      my @p = $body->find('li');

      @p = map{[
        split /\W+/, $_->as_text
      ]} @p;

      # make it a hash instead of an array of arrays
      my %recipe;
      my $index ='A';
      $recipe{$index++} = $_ for @p;

      $data->{$building}{recipe} = \%recipe if %recipe;
    }
  }
  $tree->delete;
  return $data;
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
    $recipe_type =~ s/\s*(?:recipe|plan)s?\s*//i;

    my @list;
    for my $a ( $table->find('tbody')->find('a') ){
      my $link = $a->attr('href');
      my $name = $a->as_text;

      $link =~ s/crashed-ship-site\K2//;

      if( substr($link,0,1) eq '/' ){
        $link = $uri_root.$link;
      }

      $info{$name} = {
        wiki => $link,
        type => $recipe_type,
      };

      my $next = $a->right;
      $next = $next->as_text if ref $next;
      next unless $next;
      if( $next =~ /[(] \s* ([^()]+?) \s* [)]/x ){
        $info{$name}{extra} = "$1";
      }
    }
  }
  $tree->delete;
  return \%info;
}

1;
