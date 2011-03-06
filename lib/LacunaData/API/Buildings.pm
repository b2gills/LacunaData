package LacunaData::API::Buildings;
use strict;
use warnings;
use 5.12.2;

use Scalar::Util qw'blessed weaken reftype';
use List::MoreUtils qw'uniq';

require LacunaData::API::Service;
require LacunaData::API::Building;

use namespace::clean;

=head1 NAME

LacunaData::API::Buildings

=head1 METHODS

=over 4

=item C<new( $data )>

=cut

sub new{
  my($class,$data) = @_;
  
  my $self = bless $data, $class;
  
  return $self;
}

=item C<list_all>

Returns sorted list of all buildings.

=cut

sub list_all{
  my($self) = @_;
  my @list = grep { lc($_) ne $_ } keys %$self;
  push @list, $self->list_simple;
  
  @list = uniq sort @list;
  
  return @list if wantarray;
  return \@list;
}

=item C<list_simple>

Returns sorted list of buildings with only basic services.

=cut

sub list_simple{
  my($self) = @_;
  my $list = $self->{_simple};
  # should already be sorted
  
  return @$list if wantarray;
  return [@$list];
}

=item C<list_complex>

Returns sorted list of buildings with additional services.

=cut

sub list_complex{
  my($self) = @_;
  my $simple = $self->{_simple};
  
  my @list = sort grep {
    lc($_) ne $_ and
    not $_ ~~ $simple
  } keys %$self;
  
  return @list if wantarray;
  return \@list;
}

=item C<list_targets>

Returns list of building targets.

=cut

sub list_targets{
  my($self) = @_;
  my @targets = map{
    $self->building($_)->target;
  } $self->list_all;
  
  return @targets if wantarray;
  return \@targets;
}

=item C<services_map>

Returns list of services for each building.

e.g.

    {
      /bean => [ view, demolish, ... ],
    }

=cut

sub services_map{
  my($self) = @_;
  
  my %services;
  
  for my $name( $self->list_all ){
    next if substr($name, 0, 1) eq '_';
    
    my $data = $self->building($name);
    
    $services{$data->target} = $data->list_services;
  }
  
  return %services if wantarray;
  return \%services;
}

=item services_list

flattened list of services available for all buildings

e.g.

    /bean/view
    /bean/demolish

=cut

sub services_list{
  my($self) = @_;
  
  my @services;
  
  my %map = $self->services_map;
  
  while( my($target,$service) = each %map ){
    push @services, map{ "$target/$_" } @$service;
  }
  
  @services = sort @services;
  
  return @services if wantarray;
  return \@services;
}

=item C<building( $building )>

Returns L<building|LacunaData::API::Building> by the name of C<$building>

=cut

sub building{
  my($self,$building) = @_;
  
  if( substr($building, 0, 1) eq '_' ){
    die;
  }
  
  my $common = $self->{_common};
  
  if( my $obj = $self->{$building} ){
    unless( blessed $obj ){
      die $building if reftype($obj) ne "HASH";
      $self->{$building} = $obj =
        LacunaData::API::Building->new($building,$obj,$common);
    }
    return $obj;
  }elsif( $building ~~ $self->{_simple} ){
    my $obj = LacunaData::API::Building->new($building,undef,$common);
    $self->{$building} = $obj;
    return $obj;
  }else{
    die;
  }
}

=item C<get_target( $target )>

Returns L<building|LacunaData::API::Building> referred to by C<$target>.

=cut

sub get_target{
  my($self,$target) = @_;
  
  die unless substr($target, 0, 1) eq '/';
  
  unless( $self->{_target} ){
    my %target;
    
    for my $name( keys %$self ){
      next if substr($name, 0, 1) eq '_';
      my $lc = lc $name;
      my $data = $self->$lc;
      
      $target{ $data->target } = $name;
    }
    
    for my $name( @{ $self->{_simple} } ){
      $target{'/'.lc $name} = $name;
    }
    
    $self->{_target} = \%target;
  }
  
  if( my $name = $self->{_target} ){
    return $self->building($name);
  }else{
    die;
  }
}

1;
