package LacunaData::Load::Changes;
use strict;
use warnings;
use autodie;
use 5.10.1;

use LacunaData::Sources (
  id => ['changes'],
  qw(
    source_file
    get_source_from_url
  )
);

use namespace::clean;

=head1 NAME

LacunaData::Load::Changes

=head2 C<Load>

=head2 C<Cache>

Stores a cleaned up local copy of the simple data.

=cut

sub Load{
}

sub Cache{
  open my $fh, '>', source_file;
  my $file = get_source_from_url;

  # remove spaces from the end of lines
  $file =~ s/(?:(?=\N)\s)+$//gm;

  # remove duplicates
  my %changes;
  my $current;
  for( split /\n/m, $file ){
    if( /^(\d+[.]\d+)/ ){
      $current = $changes{$1} = [];
    }
    push @$current, $_;
  }

  for my $key ( sort { $b <=> $a } keys %changes ){
    my $value = $changes{$key};
    print {$fh} $_, "\n" for @$value;
  }

  #print {$fh} $file;
  close $fh;

  # return the data structure unless called in void context
  #if( defined wantarray ){
  #}
  return;
}
1;
