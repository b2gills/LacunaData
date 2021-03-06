package LacunaData::Load::API::HTML;
use strict;
use warnings;
use 5.12.2;
BEGIN {
  if ( $] >= 5.020_000 ){
    require experimental;
    experimental->import('smartmatch');
  }
}

use HTML::TreeBuilder 5 -weak;
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

    unless( $text =~ /all \w+s share./i ){
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
  my($arg_order,$arg_order_set);

  for my $elem ( @tail ){
    my $tag  = $elem->tag;
    my $text = $elem->as_text;

    given( $tag ){
      when( 'h1' ){ last } # skip any POD ERRORS section
      when( 'h2' ){
        my($name,$args) = $text =~ /(\w+) \s* \(\s* (.*?) \s*\)/x;

        my $is_object;
        if( $args ){
          $is_object = $method{$name}{'is-object'} = !!($args =~ s/^ \{ \s* (.*?) \s* \} $/$1/x);
        }else{
          $name //= $text;
          $args = '';
        }

        $method = $method{$name} //= {};

        my @args = map{
          $a = "$_";
          $a =~ s/^ \s* \[ \s*  //x;
          $a =~ s/  \s* \] \s* $//x;
          $a
        } split / \s* \[? \s* , [ ]/x, $args;

        if( $is_object ){
          my $arg_info = $method->{'arg-info'} //= {};
          for( @args ){
            ($_,my $desc) = split / \s* (?: : | => ) \s* /x;
            $arg_info->{$_} = undef;
          }
        }

        if( @args && $args[0] !~ /^param/ ){
          # We know the argument names ahead of time
          $arg_order = $method->{'arg-order'} = \@args;
          $arg_order_set = 1;
        }else{
          # Pick up the argument names as they come
          undef $arg_order;
          $arg_order_set = 0;
        }

        undef $arg;
        undef $arg2;
      }
      when( 'p' ){
        if( $arg and $method ){

          my $arg_info = $method->{'arg-info'} //= {};

          if($arg2){
            unless(ref $arg_info->{$arg} ){
              $arg_info->{$arg} = {
                _description => $arg_info->{$arg}
              }
            }

            my $arg2_info = $arg_info->{$arg}{$arg2} //= {};

            if( $arg2_info->{description} ){
              $arg2_info->{description} .= ' ' . $text
            }else{
              $arg2_info->{description} = $text;
            }
          }else{
            if( $arg_info->{$arg} ){
              $arg_info->{$arg} .= ' ' . $text;
            }else{
              $arg_info->{$arg} = $text;
            }
            if( $text =~ /\b(?: defaults? | optional )\b/xi ){
              $method->{required}{$arg} = 0;
            }
          }
        }elsif( $method ){
          if( $text =~ /^throw\D*(.*)/i ){
            my @throws = sort {$a<=>$b} split /\D+/, $1;
            $method->{throws} = \@throws;
          }else{
            $text =~ s/\s* (?: It\s*)? Returns:? \s* $//ix;
            no warnings 'uninitialized';
            $method->{description} .= $text;
          }
        }
      }
      when( 'pre' ){
        if( $method ){
          next unless $text =~ /\s*[{]/;
          $text =~ s/^\s* ( [{\[0-9] )     /$1/x;
          $text =~ s/     ( [}\]0-9] ) \s*$/$1/x;
          $method->{returns} = $text;
        }
      }
      when( 'h3' ){
        my($temp,$required) = $text =~ /(\w+) \s* \(\s* (.*?) \s*\)/x;
        if( defined $temp ){
          next if $required =~ /^original/;
          $arg = $temp;
          $required = $required eq 'required' || 0;
          $method->{required}{$arg} = $required;
        }else{
          next if $text eq 'named arguments';
          $arg = $text;
        }
        if( $arg =~ /^param/ and not $arg_order ){
          $arg_order_set = 1;
        }

        push @$arg_order, $arg unless $arg_order_set;
        undef $arg2;
      }
      when( 'h4' ){
        $arg2 = $text;
      }
    }
    if( $method and $arg_order ){
      if( @$arg_order and $arg_order->[-1] eq 'RESPONSE' ){
        pop @$arg_order;
      }
      $method->{'arg-order'} ||= $arg_order
    }
  }
  $method = undef;

  while( my($method,$data) = each %method ){
    my $order = delete $data->{'arg-order'};
    my $info  = delete $data->{'arg-info'};
    my $required = delete $data->{required};
    my $is_object = delete $data->{'is-object'};

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
            if( $required ){
              $param{required} = $required->{$name} // 1;
            }else{
              $param{required} = 1;
            }
          }
        }
        if( $is_object ){
          $data->{parameters}{ delete $param{name} } = \%param;
        }else{
          push @{$data->{parameters}}, \%param;
        }
      }
    }elsif( $info->{params} ){
      delete $info->{params}{_description} if ref $info->{params};
      $data->{parameters} = $info->{params};
    }
  }

  return \%method;
}

use namespace::clean;

1;
