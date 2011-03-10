use strict;
use warnings;

use Test::More tests => 9;
use Test::Moose;

my $base = 'LacunaData::API';
my $package = "${base}::Building";
my $package_service = "${base}::Service";

use_ok $package;

my %building = (
  name => 'Test',
  services => {
    testing => {  }
  }
);

my $building = new_ok $package, [ %building ], 'building';

is $building->name, 'Test', 'building->name';

is_deeply [$building->list_services], ['testing'], 'building->list_services';

my $service = $building->service('testing');

isa_ok
  $service,
  $package_service,
  'building->service("testing")';

is $building->target, '/test', 'building->target';


ok !$building->is_simple, 'building->is_simple == False';
my $simple = new_ok $package, [
  name => 'Simple',
  services => {},
  simple => 1,
], 'simple_building';
ok $simple->is_simple, 'simple_building->is_simple == True';

done_testing;
