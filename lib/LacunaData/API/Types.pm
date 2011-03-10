package LacunaData::API::Types;

use MooseX::Types
-declare => [qw{
  Param    ParamList
  Service  ServiceList
  Building BuildingList
  ParamArray ParamHash
  Target
}];
use MooseX::Types::Moose ':all';

use Scalar::Util qw'blessed';

use namespace::clean;

coerce Bool,
from Any,
via {
  $_ ? 1 : '';
};

=head1 TYPES

=over 4

=item C<Target>

=cut

subtype Target,
as Str,
where {
  $_ eq ''
  or
  substr($_,0,1) eq '/'
  and
  $_ eq lc $_
};# mesage { '' }

=item C<Param>

=cut

class_type Param, {
  class => 'LacunaData::API::Service::ParamItem',
};

coerce Param,
from HashRef[Str],
via {
  Param()->new(%$_);
};

=item C<ParamList>

=cut

role_type ParamList,{
  role => 'LacunaData::API::Service::ParamList',
};

coerce ParamList,
from HashRef,
via {
  require LacunaData::API::Service::ParamHash;
  LacunaData::API::Service::ParamHash->new(
    params => $_
  );
};

coerce ParamList,
from ArrayRef,
via {
  require LacunaData::API::Service::ParamArray;
  LacunaData::API::Service::ParamArray->new(
    params => $_
  );
};

=item C<ParamHash>

=cut

subtype ParamHash,
as HashRef[Param];

coerce ParamHash,
from HashRef,
via {
  require LacunaData::API::Service::ParamItem;
  while( my($k,$v) = each %$_ ){
    $_->{$k} = LacunaData::API::Service::ParamItem->new(
      name => $k,
      %$v,
    );
  }
  $_;
};

=item C<ParamArray>

=cut

subtype ParamArray,
as ArrayRef[Param];

coerce ParamArray,
from ArrayRef,
via {
  require LacunaData::API::Service::ParamItem;
  my @out;
  for( @$_ ){
    push @out, LacunaData::API::Service::ParamItem->new(
      %$_
    );
  }
  \@out;
};

=item C<Service>

=cut

class_type Service, {
  class => 'LacunaData::API::Service',
};

=item C<ServiceList>

=cut

subtype ServiceList,
as HashRef[Service];

coerce ServiceList,
from HashRef,
via {
  require LacunaData::API::Service;
  while( my($k,$v) = each %$_ ){
    next if blessed $v;
    $_->{$k} = LacunaData::API::Service->new(
      name => $k,
      %$v
    )
  }
  $_
};

=item C<Building>

=cut

class_type Building, {
  class => 'LacunaData::API::Building',
};

=item C<BuildingList>

=cut

subtype BuildingList,
as HashRef[Building];

coerce BuildingList,
from HashRef,
via {
  require LacunaData::API::Building;
  while( my($k,$v) = each %$_ ){
    $_->{$k} = LacunaData::API::Building->new(
      name => $k,
      %$v
    )
  }
  $_
};

=back

=cut

no MooseX::Types;
1;
