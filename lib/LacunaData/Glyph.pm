package LacunaData::Glyph;
use strict;
use warnings;
use autodie;

use LacunaData::Sources;
use LacunaData::Load::Glyph;

use Scalar::Util qw'reftype';
use List::MoreUtils qw'uniq';
use 5.12.2;

use namespace::clean;

=head1 NAME

LacunaData::Glyph

=head2 METHODS

=over 4

=item C<new>

creates a new LacunaData::Glyph object

=cut

sub new{
  my($class) = @_;
  my $self = LacunaData::Load::Glyph->Load;
  bless $self, $class;
  return $self;
}

no namespace::clean;

sub _mixed_sort{
  my $common;
  my $la = length $a;
  my $lb = length $b;
  
  my $i = 1;
  for( ; $i < $la && $i < $lb; $i++ ){
    last unless substr($a,$i,1) eq substr($b,$i,1);
  }
  
  if( substr($a,$i,1) ~~ ['0'..'9'] ){
    return substr($a,$i) <=> substr($b,$i);
  }
  return $a cmp $b;
}

sub mixed_sort{
  sort {_mixed_sort} @_
}

use namespace::clean;

=item C<building_list>

returns list of glyph buildings with known receipes

=cut

sub building_list{
  my($self) = @_;
 
  return mixed_sort keys %$self;
}

=item C<functional>

returns list of glyph buildings which are more than decorations

=cut

sub functional{
  my($self) = @_;
  my @functional = sort grep{
    $self->{$_}{type} eq 'functional'
  } keys %$self;
  return @functional;
}

=item C<decorative>

returns list of glyph buildings which are just decorative

=cut

sub decorative{
  my($self) = @_;
  my @functional = mixed_sort grep{
    $self->{$_}{type} eq 'decorative'
  } keys %$self;
  return @functional;
}

=item C<loop( &code )>

Runs through the sorted list of known recipes.

Calls C<&code> with an object representing the current recipe.

Returns a list of the return values of the called C<&code>.

=cut

sub loop{
  my($self,$code) = @_;
  my $opaque = [];
  for my $name ( mixed_sort keys %$self ){
    my $data = $self->{$name};
    my $reftype = reftype $data->{recipe};
    if( $reftype eq 'ARRAY' ){
      _loop($data,$name,$code,$opaque);
    }elsif( $reftype eq 'HASH' ){
      my $type = $data->{type};
      for my $recipe_name ( sort keys %{$data->{recipe}} ){
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

no namespace::clean;

sub _loop{
  my($data,$name,$code,$opaque) = @_;
  my $elem = LacunaData::Glyph::Building->new($data,$name);
  local $_ = $elem;
  my @return = $code->($elem);
  push @$opaque, @return;
}

use namespace::clean;

=pod

The recipe object has these methods:

=over 4

=item C<type>

Returns the type of the building this recipe is for.

one of C<functional> or C<decorative>

=item C<name>

Returns the name of the building this recipe is for.

If there is more than one recipe for a given building,
this will return the B<same> name for each recipe.

=item C<recipe>

Returns a list of the glyphs for this recipe, in the required order.

=cut

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
