package LacunaData::API::Basic;

use MooseX::Types::Moose qw':all';
use LacunaData::API::Types qw':all';

use namespace::clean;
use Moose;
use MooseX::AttributeHelpers;

has name => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has target => (
  is => 'ro',
  isa => Target,
  lazy => 1,
  default => sub{
    my($self) = @_;
    return '/'.lc $self->name;
  }
);

has services => (
  metaclass => 'Collection::Hash',
  is => 'ro',
  isa => ServiceList,
  required => 1,
  coerce => 1,
  auto_deref => 1,
  provides => {qw{
    get   service
    keys  list_services
  }},
);

1;

=head1 ATTRIBUTES

=over 4

=item C<name>

=item C<target>

=item C<services>

=back

=head1 METHODS

=over 4

=item C<service($name)>

=item C<list_services>

=back

=cut
