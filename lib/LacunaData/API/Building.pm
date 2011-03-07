package LacunaData::API::Building;
use strict;
use warnings;
use 5.12.2;

require LacunaData::API::Basic;
our @ISA = qw'LacunaData::API::Basic';

use Scalar::Util qw'blessed reftype';
use List::MoreUtils qw'uniq';

use namespace::clean;

=head1 NAME

LacunaData::API::Building

=head1 METHODS

=over 4

=item C<new( $name, $data, $common )>

=cut

sub new{
  my($class,$name,$data,$common) = @_;
  $data = {} unless ref $data;
  
  $data->{_common} = { %$common };
  $data->{name} = $name;
  bless $data,$class;
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
  
  if( my $common = delete $self->{_common}{$service} ){
    unless( blessed $common ){
      $common->{_is_common} = 1;
      $common = LacunaData::API::Service->new($service,$common)
    }
    $services->{$service} = $common;
    return $common;
  }elsif( my $obj = $services->{$service} ){
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
  
  my @services = keys %{ $self->{services} };
  push @services, keys %{ $self->{_common} };
  
  @services = uniq sort @services;
  
  return @services if wantarray;
  return \@services;
}

1;
