package LacunaData::Resources;
use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [ qw(
    ore_list food_list resource_list
    all_food_list normalize_food
  ) ],
};

=head1 NAME

LacunaData::Resources

=head2 C<ore_list>

returns sorted list of ore types

=cut

my @ore = qw( anthracite bauxite beryl chalcopyrite chromite fluorite galena goethite gold gypsum halite kerogen magnetite methane monazite rutile sulfur trona uraninite zircon );
sub ore_list{
  @ore
}

=head2 C<food_list>

returns sorted list of food types

=cut

my @food = qw( algae apple bean beetle bread burger cheese chip cider corn fungus lapis meal milk pancake pie potato root shake soup syrup wheat );
sub food_list{
  @food
}

my %normalize_food = (qw(
  beeldeban  beetle
  dairy      milk
  denton     root
  malcud     fungus
), map{ $_, $_ } @food);

=head2 C<all_food_list>

returns a sorted list of food related words

=cut

my @all_food = sort keys %normalize_food;
sub all_food_list{
  @all_food
}

=head2 C<normalize_food>

returns the the food type that corresponds to the given word

=cut

sub normalize_food{
  return unless @_;

  my @food = map{
    $normalize_food{ lc $_ }
  } @_;

  if( @_ == 1 ){
    return unless $food[0];
    return $food[0];
  }else{
    return @food;
  }
}

=head2 C<resource_list>

returns full list of all resources

(excludes waste)

=cut

my @resource = ( @food, @ore, qw'water energy' );
sub resource_list{
  @resource
}
