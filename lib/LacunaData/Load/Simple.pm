package LacunaData::Load::Simple;
use strict;
use warnings;
use autodie;

use LacunaData::Sources (
  id => [],
  qw(
    simple_downloads
    source_file
    get_source_from_url
  )
);

use namespace::clean;

=head1 NAME

LacunaData::Load::SMD

=head2 C<Load>

=head2 C<Cache>

Stores a cleaned up local copy of the simple data.

=cut

sub Load{
}

sub Cache{
  my @simple = simple_downloads;

  for my $item (@simple){
    print STDERR "$item\r";

    open my $fh, '>', source_file($item);
    print {$fh} get_source_from_url($item);
    close $fh;

    print STDERR ' ' x length $item, "\r";
  }

  # return the data structure unless called in void context
  #if( defined wantarray ){
  #}
  return;
}
1;
