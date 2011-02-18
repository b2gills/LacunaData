package LacunaData::API::Service;
use strict;
use warnings;
use 5.12.2;

=head1 NAME

LacunaData::API::Service

=head1 MODULES

=over 4

=item C<new( $name, $data )>

=item C<name>

=cut

sub new{
  my($class,$name,$data) = @_;
  $data->{name} = $name;
  bless $data, $class;
}

sub name{
  my($self) = @_;
  return $self->{name};
}

1;
