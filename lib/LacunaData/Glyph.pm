package LacunaData::Glyph;
use strict;
use warnings;
use autodie;

use LacunaData::Sources;
use LacunaData::Resources 'ore_list';
use HTML::TreeBuilder;
use YAML qw'thaw Dump DumpFile';
use LWP::Simple;
use Scalar::Util qw'reftype';
use List::MoreUtils qw'uniq';
use 5.12.2;

my $data;
eval{
  $data = thaw(LacunaData::Sources->get_source('glyph-data','file'));
  bless $data, __PACKAGE__;
} or do{
  $data = bless {}, __PACKAGE__;
  $data->rebuild;

  DumpFile( LacunaData::Sources->file_for('glyph-data'), {%$data} );
};

sub object{
  return $data;
}

sub building_list{
  my($self) = @_;
 
  return keys %$self;
}

sub functional{
  my($self) = @_;
  my @functional = grep{
    $self->{$_}{type} eq 'functional'
  } keys %$self;
  return @functional;
}
sub decorative{
  my($self) = @_;
  my @functional = grep{
    $self->{$_}{type} eq 'decorative'
  } keys %$self;
  return @functional;
}

sub loop{
  my($self,$code) = @_;
  my $opaque = [];
  while( my($name,$data) = each %$self ){
    my $reftype = reftype $data->{recipe};
    if( $reftype eq 'ARRAY' ){
      _loop($data,$name,$code,$opaque);
    }elsif( $reftype eq 'HASH' ){
      my $type = $data->{type};
      for my $recipe_name ( keys %{$data->{recipe}} ){
        my %data = (
          type => $type,
          recipe => $data->{recipe}{$recipe_name},
        );
        my $current_name = "$name ($recipe_name)";
        _loop(\%data,$current_name,$code,$opaque);
      }
    }
  }
  return @$opaque;
}
sub _loop{
  my($data,$name,$code,$opaque) = @_;
  my $elem = LacunaData::Glyph::Building->new($data,$name);
  local $_ = $elem;
  my @return = $code->($elem);
  push @$opaque, @return;
}

sub rebuild{
  my($self) = @_;
 
  $self->reload_list();
 
  for my $building ( sort $self->building_list ){
    $self->_load($building);
  }
 
  return $self;
}

my @ore_list = ore_list;
sub _only_png{
  my $alt = lc $_->attr('alt');
  return unless $alt;
  return unless $alt =~ /(.*)\.png/;
  $alt = $1;
  return unless $alt ~~ @ore_list;
  return $alt;
}

sub _load{
  my($self,$building) = @_;
 
  say STDERR 'loading ', $building;
 
  my $tree = HTML::TreeBuilder->new();
  {
    my $url = $self->{$building}{wiki};
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
 
  # ignore anything that can't be a glyph
  my @glyphs = map _only_png, $body->find('img');
 
  if( @glyphs ){
    $self->{$building}{recipe} = \@glyphs;
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
   
    $self->{$building}{recipe} = \%recipe;
  }
}

sub reload_list{
  my($self) = @_;
 
  my $tree = HTML::TreeBuilder->new();
  {
    my $content = LacunaData::Sources->get_source('glyph-list');
    $tree->parse_content($content);
  }
  my $uri = LacunaData::Sources->url_for('glyph-list');
  $uri =~ m(^( \w+ :// [^/]+ ))x;
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
      $self->{$name} = {
        wiki => $link,
        type => $recipe_type,
      };
    }
  }
 
  return $self;
}

{
  package LacunaData::Glyph::Building;
  sub new{
    my($class,$data,$name) = @_;
    bless $data,$class;
    $data->{name} = $name;
    return $data;
  }
  BEGIN{
    no strict 'refs';
    for my $method ( qw'type name' ){
      *$method = sub{
        my($self) = @_;
        return $self->{$method};
      }
    }
    for my $method ( qw'recipe' ){
      *$method = sub{
        my($self) = @_;
        my $return = $self->{$method};
        return @$return if wantarray;
        return [@$return];
      }
    }
  }
}

1;
