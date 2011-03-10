package LacunaData::API::Service::ParamItem;
use MooseX::Types::Moose ':all';
use LacunaData::API::Types ':all';

use namespace::clean;
use Moose;

has name => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has description => (
  is => 'rw',
  isa => Str,
);

has optional => (
  is => 'ro',
  isa => Bool,
  coerce => 1,
  trigger => sub{
    my($self,$new) = @_;
    $self->{optional} = $new ? 1 : 0;
  }
);

has type => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => sub{
    my($self) = @_;
    return 'string' unless $self->has_object;
    return $self->object->type;
  },
);

has object => (
  is => 'ro',
  does => ParamList,
  coerce => 1,
  predicate => 'has_object',
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 ATTRIBUTES

=over 4

=item C<name>

=item C<description>

=item C<optional>

=item C<type>

=item C<object>

=back

=head1 METHODS

=over 4

=item C<has_object>

=back

=cut
