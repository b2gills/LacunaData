package LacunaData::Load::ErrorCodes;
use strict;
use warnings;
use 5.12.2;
use autodie;

use YAML qw'freeze thaw';

use HTML::TreeBuilder;

use LacunaData::Sources (
  id => ['error-codes'],
  qw(
    source_file
    source_url
    get_source_from_file
    get_source_from_url
  )
);
use LacunaData::Sources (
  id => ['error-code-id'],
  get_source_from_file => { -as => 'error_code_id' },
);

use namespace::clean;

=head1 NAME

LacunaData::Load::ErrorCodes

=head2 C<Load>

Returns information about the Lacuna Expanse API error codes.

=cut

sub Load{
  if( -e source_file ){
    return thaw( get_source_from_file );
  }else{
    return _load();
  }
}

no namespace::clean;

sub _load{
  my $tree = HTML::TreeBuilder->new_from_content( get_source_from_url );
  
  my $h1 = $tree->find('h1');
  
  my $id;
  my %error;
  for my $elem ( $h1->right ){
    next unless ref $elem;
    given( $elem->tag ){
      no warnings 'uninitialized';
      when( 'h2' ){
        my $name;
        ($id,$name) = $elem->as_text =~ /(\d+)\s*(.*)/;
        $error{$id}{name} = $name;
      }
      next unless $id;
      when( 'p' ){
        $error{$id}{reason} .= $elem->as_text;
      }
    }
  }
  
  $tree->delete();
  my $ids = thaw error_code_id;
  while( my($num,$id) = each %$ids ){
    $error{$num}{id} = $id;
  }
  
  return \%error;
}

use namespace::clean;

=head2 C<Cache>

Generate information about the Lacuna Expanse API, excluding the buildings.

It does this by looking over the web pages for the API.

It then saves a copy of this data.

=cut

sub Cache{
  my $data = _load();

  open my $fh, '>', source_file;
  print {$fh} freeze($data);
  close $fh;
  
  return $data;
}
1;
