package LacunaData::API::Basic;
use strict;
use warnings;
use 5.12.2;

use Scalar::Util qw'blessed';

use namespace::clean;

=head1 NAME

LacunaData::API::Basic

=head1 METHODS

=over 4

=item C<new( $name, $data )>

=cut

sub new{
  my($class,$name,$data) = @_;
  $data->{name} = $name;
  my $self = bless $data, $class;
  
  return $self;
}

=item C<name>

Returns the name of the module.

=cut

sub name{
  my($self) = @_;
  return $self->{name};
}

=item C<service( $service )>

Returns the service named C<$service>.

=cut

sub service{
  my($self,$service) = @_;
  if( substr($service,0,1) eq '_' ){
    die;
  }
  
  my $services = $self->{services};
  
  if( my $obj = $services->{$service} ){
    unless( blessed $obj ){
      $obj = LacunaData::API::Service->new($service,$obj);
      $services->{$service} = $obj;
    }
    return $obj;
  }else{
    die;
  }
}

=item C<list_services>

Returns a sorted list of available services for this module.

=cut

sub list_services{
  my($self) = @_;
  
  my @services = sort keys %{ $self->{services} };
  
  return @services if wantarray;
  return \@services;
}

=item C<target>

Returns the target for this module.

e.g.

    /empire

=cut

sub target{
  my($self) = @_;
  return $self->{target} || '/'.lc $self->name;
}

1;
