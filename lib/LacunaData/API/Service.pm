package LacunaData::API::Service;

use LacunaData::API::Types ':all';
use MooseX::Types::Moose ':all';

use namespace::clean;
use Moose;

has name => (
  is => 'ro',
  isa => Str,
  required => 1,
);
has parameters => (
  is => 'ro',
  isa => ParamList,
  coerce => 1,
  default => sub{[]},
  handles => {qw{
    list_params list_names
    get_param get
  }},
);
has description => (
  is => 'rw',
  isa => Str,
);

# only relevant to buildings
has is_common => (
  is => 'ro',
  isa => Bool,
  init_arg => 'common',
);
has returns => (
  is => 'rw',
  isa => Str,
);
has throws => (
  is => 'rw',
  isa => ArrayRef[Int],
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 ATTRIBUTES

=over 4

=item C<name>

=item C<parameters>

=item C<description>

=item C<is_common>

initial arg is C<common>

=item C<returns>

=item C<throws>

=back

=cut
