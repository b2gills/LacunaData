package LacunaData::Glyph;
use strict;
use warnings;
use autodie;

use LacunaData::Sources;
use LacunaData::Load::Glyph;

use Scalar::Util qw'reftype';
use List::MoreUtils qw'uniq';
use 5.12.2;

sub new{
  my($class) = @_;
  my $self = LacunaData::Load::Glyph->Load;
  bless $self, $class;
  return $self;
}

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

sub building_list{
  my($self) = @_;
 
  return mixed_sort keys %$self;
}

sub functional{
  my($self) = @_;
  my @functional = sort grep{
    $self->{$_}{type} eq 'functional'
  } keys %$self;
  return @functional;
}

sub decorative{
  my($self) = @_;
  my @functional = mixed_sort grep{
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
