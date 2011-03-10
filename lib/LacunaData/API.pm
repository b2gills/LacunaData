package LacunaData::API;
use strict;
use warnings;
use 5.12.2;

use Scalar::Util qw'reftype blessed weaken';

require LacunaData::API::Buildings;
require LacunaData::API::Basic;

use namespace::clean;

=head1 NAME

LacunaData::API

=head2 METHODS

=over 4

=item Load

=cut

sub Load{
  my($class,%opt) = @_;
  unless( $opt{smd} ){
    require LacunaData::Load::SMD;
    $opt{smd} = LacunaData::Load::SMD->Load;
  }
  unless( $opt{api} ){
    require LacunaData::Load::BuildingAPI;
    $opt{api} = LacunaData::Load::BuildingAPI->Load;
  }
  unless( $opt{other} ){
    require LacunaData::Load::OtherAPI;
    $opt{other} = LacunaData::Load::OtherAPI->Load;
  }

  my $smd = clean_smd($opt{smd});

  fix_smd($smd,$opt{api});
  add_smd($smd->{Buildings},$opt{api});
  add_smd($smd,$opt{other});

  my $self = bless $smd, $class;

  $self->{Buildings} = LacunaData::API::Buildings->new(
    $self->{Buildings}
  );

  while( my($k,$v) = each %$self ){
    next if blessed $v;
    $self->{$k} = LacunaData::API::Basic->new(
      name => $k,
      %$v
    )
  }

  return $self;
}

no namespace::clean;

my @smd_main_remove = qw{
  SMDVersion
  envelope
  transport
};

sub clean_smd{
  my($smd) = @_;

  while( my($name,$data) = each %$smd ){
    if( $name eq 'Buildings' ){
      clean_smd($data);
      $data->{_common} = $data->{Generic}{services};
      delete $data->{Generic};
      next;
    }
    delete @$data{@smd_main_remove};

    for( values %{ $data->{services} } ){
      delete $_->{returns};
    }
  }
  return $smd;
}

my %add_smd_jump = (
  HASH  => \&_add_smd_h,
  ARRAY => \&_add_smd_a,
);

sub _add_smd_h{
  my($acc,$add) = @_;

  while( my ($name,$data) = each %$add ){
    my $acc_data = $acc->{$name};
    if( $acc_data ){
      add_smd($acc_data,$data);
    }else{
      $acc->{$name} = $data
    }
  }

  return $acc;
}

sub _add_smd_a{
  my($acc,$add) = @_;

  for( my $i = 0; $i<@$add; $i++ ){
    my $add_data = $add->[$i];
    my $acc_data = $acc->[$i];

    if( $acc_data ){
      add_smd($acc_data,$add_data);
    }else{
      $acc->[$i] = $add_data
    }
  }

  return $acc;
}

sub add_smd{
  my($acc,$add) = @_;

  my $reftype = reftype $add;
  return unless $reftype;
  return unless reftype $acc eq $reftype;
  return unless exists $add_smd_jump{$reftype};
  $add_smd_jump{$reftype}->($acc,$add)
}

#the SMD has names that don't match their targets

sub fix_smd{
  my($smd,$building_api) = @_;
  my $buildings = $smd->{Buildings};

  $building_api->{_common} = delete $building_api->{common};
  $building_api->{_simple} = delete $building_api->{simple};
  my %match = map { '/'.lc($_), $_ } keys %$building_api;

  while( my($name,$data) = each %$buildings ){
    next if substr($name,0,1) eq '_';
    next if $name eq lc $name;
    my $reftype = reftype $data;

    my $target = $data->{target};
    next unless $target;

    my $match = $match{$target};
    die unless $match;

    $data->{_smd_name} = $name;
    next if $match eq $name;

    delete $buildings->{$name};
    $buildings->{$match} = $data;
  }
}

use namespace::clean;

=item alliance

=item chat

=item empire

=item inbox

=item map

=item body

=item stats

returns an object of type L<LacunaData::API::Basic>

=item buildings

returns an object of type L<LacunaData::API::Buildings>

=cut

BEGIN{
  my @keys = qw{
    Alliance
    Chat
    Captcha
    Buildings
    Empire
    Inbox
    Map
    Body
    Stats
  };

  my %map = map { lc($_), $_ } @keys;

  while( my($subname,$origin) = each %map ){
    no strict 'refs';
    *$subname = sub{
      my($self) = @_;
      my $obj = $self->{$origin};
      return $obj if $obj;
      return;
    };
  }
}

=item building

convenience method for C<< $self->buildings->building($building) >>

=cut

sub building{
  my($self,$building) = @_;
  return $self->buildings->building($building);
}

=item list_targets

returns a sorted list of known targets

e.g

    /alliance
    /empire
    /bean

=cut

sub list_targets{
  my($self) = @_;

  my @targets;
  for my $name( keys %$self ){
    my $lc = lc $name;
    my $data = $self->$lc;

    if( $name eq 'Buildings' ){
      push @targets, $data->list_targets;
    }else{
      push @targets, $data->target;
    }
  }

  @targets = sort @targets;
  return @targets if wantarray;
  return \@targets;
}

=item get_target

returns an object based on it's target

=cut

sub get_target{
  my($self,$target) = @_;

  die unless substr $target, 0, 1 eq '/';

  unless( $self->{_target} ){
    my %target;

    for my $name( keys %$self ){
      next if $name eq 'Buildings';
      next if substr $name, 0, 1 eq '_';

      my $lc = lc $name;
      my $data = $self->$lc;

      $target{ $data->target } = $name;
    }

    $self->{_target} = \%target;
  }

  if( my $name = $self->{_target} ){
    return $self->{$name};
  }elsif( my $ret = $self->buildings->get_target($target) ){
    return $ret;
  }else{
    die;
  }
}

=item services_map

list of services for each target

e.g.

    {
      /empire => [ ... ],
    }

=cut

sub services_map{
  my($self) = @_;

  my %services = $self->buildings->services_map;

  for my $name( keys %$self ){
    next if $name eq 'Buildings';
    next if substr($name, 0, 1) eq '_';

    my $lc = lc $name;
    my $data = $self->$lc;

    $services{$data->target} = $data->list_services;
  }

  return %services if wantarray;
  return \%services;
}

=item services_list

flattened list of services available for all targets

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

1;
