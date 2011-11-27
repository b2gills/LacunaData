package LacunaData::API::Building;

use LacunaData::API::Types;

use namespace::clean;
use Moose;
extends 'LacunaData::API::Basic';

has is_simple => (
  is => 'ro',
  isa => 'Bool',
  init_arg => 'simple',
);

=over 4

=item C<list_additional_services>

Returns list of services exclusive to a given building.

e.g.

    assemble_glyphs, get_glyphs, search_for_glyph, ...

=back

=cut

sub list_additional_services{
  my($self) = @_;
  my %services = $self->services;
  return map{
    $_->name
  } grep {
    not $_->is_common
  } values %services;
}

1;

=head1 ATTRIBUTES

=over 4

=item C<name>

=item C<target>

=item C<services>

=item C<is_simple>

=back

=head1 METHODS

=over 4

=item C<service($name)>

=item C<list_services>

=back

=cut