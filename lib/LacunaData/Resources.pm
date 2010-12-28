package LacunaData::Resources;
use strict;
use warnings;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw'ore_list food_list';
our %EXPORT_TAGS = (
  all => [@EXPORT_OK]
);

my @ore = qw( anthracite bauxite beryl chalcopyrite chromite fluorite galena goethite gold gypsum halite kerogen magnetite methane monazite rutile sulfur trona uraninite zircon );
sub ore_list{
  @ore
}

my @food = qw( algae apple bean beetle bread burger cheese chip cider corn fungus lapis meal milk pancake pie potato root shake soup syrup wheat );
sub food_list{
  @food
}
