use strict;
use warnings;

use Test::More tests => 20;
use Test::Moose;

my $package_base  = 'LacunaData::API::Service::Param';
my $package       = "${package_base}List";
my $package_hash  = "${package_base}Hash";
my $package_array = "${package_base}Array";
my $package_param = "${package_base}Item";

for(qw{ Item List Array Hash }){
  use_ok $package_base.$_;
}

my %example = (
  a => { optional => 0 },
  b => { optional => 1 },
  c => { optional => 1 },
);
my @example = (
  { name => 'a', optional => 0 },
  { name => 'b', optional => 1 },
  { name => 'c', optional => 1 },
);
my $optional_list = [0,1,1];

my $hash  = new_ok $package_hash,  [
  params => \%example,
], 'Hash';
does_ok $hash,  $package, "Hash does $package";

my $array = new_ok $package_array, [
  params => \@example,
], 'Array';
does_ok $array, $package, "Array does $package";

is $array->get( 0 )->name, 'a', 'Array->get( 0 )';
is $array->get('0')->name, 'a', 'Array->get("0")';
is $array->get('a')->name, 'a', 'Array->get("a")';
is  $hash->get( 0 ), undef, ' Hash->get( 0 ) returns nothing';
is  $hash->get('a')->name, 'a', ' Hash->get("a")';

is_deeply [
  map {
    $hash->get($_)->optional ? 1 : 0
  } sort $hash->list_names
], $optional_list, 'Test Hash optional attr';

is_deeply [
  map {
    $array->get($_)->optional ? 1 : 0
  } $array->list_names
], $optional_list, 'Test Array optional attr';

subtest "methods required by the role $package" => sub{
  plan tests => 2*2;
  ok !$hash->positional, ' Hash->positional == False';
  ok $array->positional, 'Array->positional == True';

  is $hash->reftype,  'HASH',  ' Hash->reftype eq HASH';
  is $array->reftype, 'ARRAY', 'Array->reftype eq ARRAY';
};

subtest 'ParamList->has_params' => sub{
  plan tests => 2 + 2*2;
  my $ehash  = new_ok $package_hash,  [ params => {} ], 'Empty Hash';
  my $earray = new_ok $package_array, [ params => [] ], 'Empty Array';

  ok   $hash->has_params,  '       Hash->has_params == True';
  ok !$ehash->has_params,  'Empty  Hash->has_params == False';

  ok   $array->has_params, '      Array->has_params == True';
  ok !$earray->has_params, 'Empty Array->has_params == False';
};

subtest 'Check the type for the params' => sub{
  my $tests = $array->count + $hash->count;

  plan tests => $tests;

  for( $hash->list_names ){
    isa_ok $hash->get($_), $package_param, "Hash $_";
  }

  for( $array->list_names ){
    isa_ok $array->get($_), $package_param, "Array $_";
  }
};

subtest 'Check sorting of list method' => sub{
  plan tests => 2;
  my @example = (
    { name => 'c' },
    { name => 'b' },
    { name => 'a' },
  );
  my $param_list = [qw'c b a'];
  my $array = new_ok $package_array, [ params => \@example ], 'Array';

  is_deeply
    [$array->list_names],
    $param_list,
    q[Array->list_names isn't sorted];
};

subtest 'Multi level params' => sub{
  my %example = (
    a => {},
    b => {
      object => {},
    },
    c => {
      object => [],
    },
  );
  my @example = (
    { name => 'a' },
    { name => 'b',
      object => {},
    },
    { name => 'c',
      object => [],
    },
  );

  plan tests => 6*2;

  note 'Testing multiple level hash';
  my $hash  = new_ok $package_hash,  [ params => \%example ], 'Hash';
  is $hash->get('a')->type, 'string', 'Hash->get(a)->type eq string';
  is $hash->get('b')->type, 'object', 'Hash->get(b)->type eq object';
  isa_ok $hash->get('b')->object, $package_hash, 'Hash->get(b)->object';
  is $hash->get('c')->type, 'array', 'Hash->get(c)->type eq array';
  isa_ok $hash->get('c')->object, $package_array, 'Hash->get(c)->object';

  note 'Testing multiple level array';
  my $array = new_ok $package_array, [ params => \@example ], 'Array';
  is $array->get('a')->type, 'string', 'Array->get(a)->type eq string';
  is $array->get('b')->type, 'object', 'Array->get(b)->type eq object';
  isa_ok $array->get('b')->object, $package_hash, 'Array->get(b)->object';
  is $array->get('c')->type, 'array', 'Array->get(c)->type eq array';
  isa_ok $array->get('c')->object, $package_array, 'Array->get(c)->object';
};

done_testing;
