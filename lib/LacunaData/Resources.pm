package LacunaData::Resources;
use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [ qw'ore_list food_list resource_list' ],
};

my @ore = qw( anthracite bauxite beryl chalcopyrite chromite fluorite galena goethite gold gypsum halite kerogen magnetite methane monazite rutile sulfur trona uraninite zircon );
sub ore_list{
  @ore
}

my @food = qw( algae apple bean beetle bread burger cheese chip cider corn fungus lapis meal milk pancake pie potato root shake soup syrup wheat );
sub food_list{
  @food
}

my @resource = ( @food, @ore, qw'water energy' );
sub resource_list{
  @resource
}
