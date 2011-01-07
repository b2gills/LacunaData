package LacunaData::Load::API::HTML;
use strict;
use warnings;
use 5.12.2;

use HTML::TreeBuilder;
use LWP::Simple 'get';
use autodie qw':default get';

use namespace::clean;

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

sub html_tree{
  my($self) = @_;
  return $self->{tree} if $self->{tree};
  
  my $content = get( $self->{url} );
  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content($content);
  $self->{tree} = $tree;
  
  return $tree;
}

sub methods{
  my($self) = @_;
  my @methods = keys %{ $self->method_data };
  
  return @methods if wantarray;
  return \@methods;
}

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

  my($method,$arg);
  
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

        $method{$name}{'arg-order'} = \@args if @args;

        $method = $name;
        undef $arg;
      }
      when( 'p' ){
        if( $arg and $method ){
          $method{$method}{'arg-info'}{$arg} = $text;
        }elsif( $method ){
          if( $text =~ /^throw\D*(.*)/i ){
            my @throws = sort {$a<=>$b} split /\D+/, $1;
            $method{$method}{throws} = \@throws;
          }else{
            $text =~ s/\s* (?: It\s*)? Returns:? \s* $//ix;
            no warnings 'uninitialized';
            $method{$method}{desc} .= $text;
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
      }
    }
  }

  return \%method;
}
1;
