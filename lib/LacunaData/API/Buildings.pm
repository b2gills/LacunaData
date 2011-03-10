package LacunaData::API::Buildings;

use List::MoreUtils qw'uniq';

require LacunaData::API::Service;
require LacunaData::API::Building;

use LacunaData::API::Types ':all';

use namespace::clean;
use Moose;
use MooseX::AttributeHelpers;

has buildings => (
  metaclass => 'Collection::Hash',
  is => 'ro',
  isa => BuildingList,
  coerce => 1,
  auto_deref => 1,
  provides => {qw{
    keys list_all
    get  building
  }},
  required => 1,
);

has common_services => (
  metaclass => 'Collection::Hash',
  is => 'ro',
  isa => ServiceList,
  coerce => 1,
  auto_deref => 1,
  provides => {qw{
    get  common_service
    keys list_common_services
  }},
);

around BUILDARGS => sub{
  my($orig,$class,@args) = @_;
  if( @args == 1 ){
    my $arg = $args[0];

    my %buildings;

    my $common = delete $arg->{_common};
    my %common;
    while( my($k,$v) = each %$common ){
      $common{$k} = LacunaData::API::Service->new(
        name => $k,
        %$v,
        common => 1,
      );
    }

    my $simple = delete $arg->{_simple};
    for my $building( @$simple ){
      $buildings{$building} = LacunaData::API::Building->new(
        name => $building,
        simple => 1,
        services => {%common},
      );
    }

    while( my($building,$data) = each %$arg ){
      my %services;
      while( my($service,$data) = each %{ $data->{services} } ){
        $services{$service} = LacunaData::API::Service->new(
          name => $service,
          %$data
        );
      }
      $buildings{$building} = LacunaData::API::Building->new(
        name => $building,
        %$data,
        services => {%common,%services},
      );
    }

    $class->$orig(
      buildings => \%buildings,
      common_services => \%common,
    );
  }else{
    $class->$orig(@args);
  }
};

=item C<list_simple>

Returns sorted list of buildings with only basic services.

=cut

sub list_simple{
  my($self) = @_;
  my @list = sort grep{
    $self->building($_)->is_simple
  } $self->list_all;
  
  return @list if wantarray;
  return \@list;
}

=item C<list_complex>

Returns sorted list of buildings with additional services.

=cut

sub list_complex{
  my($self) = @_;
  my $simple = $self->{_simple};

  my @list = sort grep {
    not $self->building($_)->is_simple
  } $self->list_all;

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

    $services{$data->target} = [sort $data->list_services];
  }

  return %services if wantarray;
  return \%services;
}

sub additional_services_map{
  my($self) = @_;

  my %services;

  for my $name( $self->list_all ){
    next if substr($name, 0, 1) eq '_';

    my $data = $self->building($name);

    my @exclusive = sort $data->list_additional_services;

    next unless @exclusive;
    $services{$data->target} = \@exclusive;
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

sub additional_services_list{
  my($self) = @_;

  my @services;

  my %map = $self->additional_services_map;

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


=item C<get_target( $target )>

Returns L<building|LacunaData::API::Building> referred to by C<$target>.

=cut

sub get_target{
  my($self,$target) = @_;

  die unless substr($target, 0, 1) eq '/';

  unless( $self->{target} ){
    my %target = map{
      $self->building($_)->target, $_
    } $self->list_all;

    $self->{_target} = \%target;
  }

  if( my $name = $self->{_target}{$target} ){
    return $self->building($name);
  }else{
    die;
  }
}

1;
