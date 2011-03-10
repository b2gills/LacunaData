package LacunaData::API::Service::ParamList;
use Moose::Role;

requires qw{
  get
  list_names
  positional
  reftype
  count
  type
  order
};

sub has_params {
  my($self) = @_;
  # returns 1 or ''
  return !! $self->count
}

no Moose::Role;
1;

=head1 REQUIRES

=over 4

=item C<get($name)>

returns the parameter object of the given name.

also returns the parameter object of a given position,
if the container is an array.

=item C<list_names>

returns a list of parameter names.

Should be in the correct order if the container is an array,
otherwise the order does not matter.

=item C<positional>

returns true if the container is an array

=item C<reftype>

returns the Perl reftype of the container
( uppercase )

=item C<count>

returns the count of posible parameters

=item C<type>

returns the JSON type of the parameters
( lowercase )

=item C<order>

returns the names of the parameters, in the correct order

returns nothing if it isn't positional

=back

=head1 PROVIDES

=over 4

=item C<has_params>

returns the boolean value of $self->count

=back

=cut
