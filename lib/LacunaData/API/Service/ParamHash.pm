package LacunaData::API::Service::ParamHash;
use MooseX::Types::Moose ':all';
use LacunaData::API::Types ':all';

use namespace::clean;
use Moose;
use MooseX::AttributeHelpers;

use constant {
  positional => 0,
  reftype => 'HASH',
  type => 'object',
};
sub order{
}

has params => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => ParamHash,
  coerce => 1,
  auto_deref => 1,
  provides => {qw{
    get  get
    count count
    keys list_names
  }},
);

with 'LacunaData::API::Service::ParamList';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 METHODS

=over 4

=item C<positional>

returns 0

=item C<reftype>

returns C<HASH>

=item C<type>

returns C<object>

=item C<order>

returns C<()>

=item C<list_names>

returns a list of parameter names

=item C<count>

returns the number of possible parameters

=item C<get($name)>

returns the parameter object of the given name.

=cut
