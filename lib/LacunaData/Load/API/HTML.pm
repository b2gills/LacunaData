package LacunaData::Load::API::HTML;
use strict;
use warnings;
use 5.12.2;

use HTML::TreeBuilder;
use LWP::Simple 'get';
use autodie qw':default get';

use namespace::clean;

=head1 NAME

LacunaData::Load::API::HTML

=head1 METHODS

=over 4

=item C<new>

=cut

sub new{
  my($class,$url) = @_;

  unless( $url =~ m(^ \w+ :// )x ){
    my($package, $filename, $line) = caller;
    die "Not an url $url in call to ->new at $filename line $line\n";
  }

  my $self = bless {
    url => $url
  }, $class;

  return $self;
}

=item C<html_tree>

Returns the associated HTML::TreeBuilder object.

For internal use only.

=cut

sub html_tree{
  my($self) = @_;
  return $self->{tree} if $self->{tree};

  my $content = get( $self->{url} );
  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content($content);
  $self->{tree} = $tree;

  return $tree;
}

=item C<methods>

Returns a list of methods listed on the given page.

=cut

sub methods{
  my($self) = @_;
  my @methods = keys %{ $self->method_data };

  return @methods if wantarray;
  return \@methods;
}

=item C<method_data>

Returns the raw data of the given methods.

=cut

sub method_data{
  my($self) = @_;

  if( $self->{methods} ){
    if( wantarray ){
      return $self->{methods}, $self->{api_url}, $self->{method_text};
    }else{
      return $self->{methods};
    }
  }

  my $tree = $self->html_tree;

  my($head) = grep {
    $_->as_text =~ /\bMethods \s* $/xi
  } $tree->find('h1');

  my @tail = $head->right;
  pop @tail;

  while( @tail ){
    last unless $tail[0]->tag eq 'p';

    my $elem = shift @tail;
    my $text = $elem->as_text;

    my $code = $elem->find('code');
    if( ref $code ){
      $self->{api_url} = $code->as_text;
      next;
    }

    unless( $text =~ /all buildings share./i ){
      $self->{method_text} .= $text;
    }
  }

  $self->{methods} = _get_api_method_info(@tail);

  if( wantarray ){
    return $self->{methods}, $self->{api_url}, $self->{method_text};
  }else{
    return $self->{methods};
  }

  return $self->{methods};
}

no namespace::clean;

sub _get_api_method_info{
  my @tail = @_;

  my %method;

  my($method,$arg,$arg2);

  for my $elem ( @tail ){
    my $tag  = $elem->tag;
    my $text = $elem->as_text;

    given( $tag ){
      when( 'h1' ){ last }
      when( 'h2' ){
        my($name,$args) = $text =~ /(\w+) \s* \(\s* (.*?) \s*\)/x;
        my @args = map{
          $a = "$_";
          $a =~ s/^ \s* \[ \s*  //x;
          $a =~ s/  \s* \] \s* $//x;
          $a
        } split ', ', $args;

        if( @args && $args[0] ne 'params' ){
          $method{$name}{'arg-order'} = \@args;
        }

        $method = $name;
        undef $arg;
      }
      when( 'p' ){
        if( $arg and $method ){
          if($arg2){
            unless(ref $method{$method}{'arg-info'}{$arg} ){
              $method{$method}{'arg-info'}{$arg} = {
                _description => $method{$method}{'arg-info'}{$arg}
              }
            }
            $method{$method}{'arg-info'}{$arg}{$arg2}{description} = $text;
          }else{
            $method{$method}{'arg-info'}{$arg} = $text;
          }
        }elsif( $method ){
          if( $text =~ /^throw\D*(.*)/i ){
            my @throws = sort {$a<=>$b} split /\D+/, $1;
            $method{$method}{throws} = \@throws;
          }else{
            $text =~ s/\s* (?: It\s*)? Returns:? \s* $//ix;
            no warnings 'uninitialized';
            $method{$method}{description} .= $text;
          }
        }
      }
      when( 'pre' ){
        if( $method ){
          $text =~ s/^\s* ( [{\[0-9] )     /$1/x;
          $text =~ s/     ( [}\]0-9] ) \s*$/$1/x;
          $method{$method}{returns} = $text;
        }
      }
      when( 'h3' ){
        $arg = $text;
        undef $arg2;
      }
      when( 'h4' ){
        $arg2 = $text;
      }
    }
  }

  while( my($method,$data) = each %method ){
    my $order = delete $data->{'arg-order'};
    my $info  = delete $data->{'arg-info'};
    if( $order ){
      for my $name (@$order){
        my %param = ( name => $name );
        if( $info->{$name} ){
          if( ref $info->{$name} ){
            $param{type} = 'object';
            $param{object} = $info->{$name};
            $param{description} = delete $info->{$name}{_description};
          }else{
            $param{type} = 'string';
            $param{description} = $info->{$name};
          }
        }
        push @{$method{$method}{parameters}}, \%param;
      }
    }elsif( $info->{params} ){
      delete $info->{params}{_description} if ref $info->{params};
      $method{$method}{parameters} = $info->{params};
    }
  }

  return \%method;
}

sub DESTROY{
  my($self) = @_;
  if( $self->{tree} ){
    $self->{tree}->delete;
  }
}

use namespace::clean;

1;
