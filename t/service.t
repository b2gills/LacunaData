use strict;
use warnings;

use Test::More tests => 12;
use Test::Moose;

my $package = 'LacunaData::API::Service';
my $package_paramlist = "${package}::ParamList";

use_ok $package;

my $hash_param = {
  a => { optional => 0 },
  b => { optional => 1 },
  c => { optional => 1 },
};
my $array_param = [
  { name => 'a', optional => 0 },
  { name => 'b', optional => 1 },
  { name => 'c', optional => 1 },
];

my $service_array = new_ok $package, [
  name => 'Array',
  parameters => $array_param
], 'Service with an array of parameters';

my $service_hash = new_ok $package, [
  name => 'Hash',
  parameters => $hash_param
], 'Service with a hash of parameters';

is $service_array->name, 'Array', 'service_array->name';
is $service_hash->name,  'Hash',  'service_hash->name';

does_ok
  $service_array->parameters,
  $package_paramlist,
  "service_array->parameters does $package_paramlist";
does_ok
  $service_hash->parameters,
  $package_paramlist,
  "service_hash->parameters does $package_paramlist";

ok !$service_array->is_common, 'default->is_common == False';
my $common = new_ok $package, [
  name => 'Common',
  common => 1,
], 'Common service';
ok $common->is_common, 'Common->is_common == True';


my $service_none = new_ok $package, [
  name => 'None',
], 'Service without any defined parameters';

is $service_none->parameters->type, 'array', 'default parameters type is array';

done_testing;
