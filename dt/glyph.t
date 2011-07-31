use strict;
use warnings;

use Test::More;
END{ done_testing }

use File::Spec::Functions qw'catfile updir';
use Scalar::Util qw'reftype';
use LacunaData::Resources qw'ore_list';
use YAML qw'LoadFile';

my $glyph_filename = catfile(qw'data glyph.yml');

my $glyph_data = LoadFile $glyph_filename;


plan tests => scalar keys %$glyph_data;

my @exists = qw'description type wiki recipe';
for my $name ( sort keys %$glyph_data ){
  my $data = $glyph_data->{$name};

  note "$name:";
  subtest $name => sub{
    ok exists $data->{$_}, "$_ exists" for @exists;

    my $recipe_data = $data->{recipe};

    if( reftype $recipe_data eq 'ARRAY' ){
      check_recipe($name,@$recipe_data);

    }elsif( reftype $recipe_data eq 'HASH' ){
      # should only be a hash if there is more than one recipe
      ok scalar keys %$recipe_data > 1, 'has at least two recipes';
      for my $recipe_id ( sort keys %$recipe_data ){
        my $data = $recipe_data->{$recipe_id};
        check_recipe( "$name ($recipe_id)", @$data );
      }

    }else{
      fail 'Invalid recipe element';
    }
    done_testing;
  }
}

sub check_recipe{
  my($name,@recipe) = @_;

  subtest "Check recipe of $name" => sub{
    plan tests => scalar @recipe + 1;

    ok scalar @recipe, 'recipe has elements';
    for( @recipe ){
      is $_, lc $_, "lc $_";
    }

    done_testing;
  }
}
