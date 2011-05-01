use strict;
use warnings;

use FindBin;
use File::Spec::Functions qw'catfile updir';

use Test::More;

my $error_id_file = 'data/error-code-id.yml';
my $error_file = 'data/error-codes.yml';

use YAML 'LoadFile';

my $error_codes = eval{ LoadFile catfile $FindBin::Bin, updir, $error_file    };

unless( $error_codes ){

  plan tests => 1;
  fail "Load $error_file";

}else{

  plan tests => 1;
  {
    my @missing = grep{
      !defined $error_codes->{$_}{id}
    } keys %$error_codes;

    ok !@missing, 'check for error codes without an id';

    if( @missing ){
      diag '    ', $_ for sort @missing;
    }
  }

}
