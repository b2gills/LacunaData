package LacunaData::API::Service::ParamArray;
use MooseX::Types::Moose ':all';

use LacunaData::API::Types ':all';

use List::Util 'first';
use Scalar::Util 'looks_like_number';

use namespace::clean;
use Moose;
use MooseX::AttributeHelpers;

use constant {
  positional => 1,
  reftype => 'ARRAY',
  type => 'array',
};

has params => (
  metaclass => 'Collection::Array',
  is => 'rw',
  isa => ParamArray,
  coerce => 1,
  auto_deref => 1,
  provides => {qw{
    count count
    get get_indexed
  }},
);

sub get{
  my($self,$name) = @_;
  my $look = looks_like_number($name);
  if( $look == 1 or $look >= 9 ){
    return $self->get_indexed($name);
  }else{
    return first {
      $_->name eq $name;
    } $self->params;
  }
}

sub list_names {
  my($self) = @_;
  map {
    $_->name;
  } $self->params;
}
{ no warnings 'once';
*order = \&list_names;
}

with 'LacunaData::API::Service::ParamList';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 METHODS

=over 4

=item C<positional>

returns 1

=item C<reftype>

returns C<ARRAY>

=item C<type>

returns C<array>

=item C<order>

returns the same as C<list_names>

=item C<list_names>

returns a list of parameter names in the correct order

=item C<count>

returns the number of possible parameters

=item C<get($name)>

=item C<get($number)>

returns the parameter object of the given name.

also returns the parameter object of a given position,
when given a number

=item C<get_indexed($number)>

returns the parameter object at a given position.

=cut
