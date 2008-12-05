# $Id: WithCache.pm,v 1.4 2005/02/23 11:25:44 sekimura Exp $

package LWP::UserAgent::WithCache;
use strict;

use base qw(LWP::UserAgent);
use Cache::FileCache;

our $VERSION = '0.06';

our $HOME = $ENV{'HOME'} || $ENV{'LOGDIR'};
our %default_cache_args = (
    'namespace' => 'lwp-cache',
    'cache_root' => "$HOME/.cache",
    'default_expires_in' => 600 );

sub new {
    my $class = shift;
    my $cache_opt = shift || {};
    my $self = $class->SUPER::new(@_);
    my %cache_args = (%default_cache_args, %$cache_opt);
    $self->{cache} = Cache::FileCache->new(\%cache_args);
    return $self
}

sub request {
     my $self = shift;
     my @args = @_;
     my $request = $args[0];

     return $self->SUPER::request(@args) if $request->method ne 'GET';

     my $uri = $request->uri->as_string;
     my $cache = $self->{cache};
     my $obj = $cache->get( $uri );

     if ( defined $obj ) {

         unless (defined $obj->{expires} and $obj->{expires} <= time()) {
             return HTTP::Response->parse($obj->{as_string});
         } 

         if (defined $obj->{last_modified}) {
             $request->header('If-Modified-Since' =>
                              HTTP::Date::time2str($obj->{last_modified}));
         }

         if (defined $obj->{etag}) {
             $request->header('If-None-Match' => $obj->{etag});
         }

         $args[0] = $request;
     }

     my $res = $self->SUPER::request(@args);
     $self->set_cache($uri, $res) if $res->code eq HTTP::Status::RC_OK;

     return $res;
}

sub set_cache {
    my $self = shift;
    my ($uri, $res) = @_;
    my $cache = $self->{cache};

    $cache->set($uri,{
         content       => $res->content,
         last_modified => $res->last_modified,
         etag          => $res->header('Etag') ? $res->header('Etag') : undef,
         expires       => $res->expires ? $res->expires : undef,
         as_string     => $res->as_string,
    }); 
}

1;
__END__

=head1 NAME

LWP::UserAgent::WithCache - LWP::UserAgent extension with local cache

=head1 SYNOPSIS

  use LWP::UserAgent::WithCache;
  my %cache_opt = (
    'namespace' => 'lwp-cache',
    'cache_root' => "$HOME/.cache",
    'default_expires_in' => 600 );
  my $ua = LWP::UserAgent::WithCache->new(\%cache_opt);
  my $response = $ua->get('http://search.cpan.org/');

=head1 DESCRIPTION

LWP::UserAgent::WithCache is a LWP::UserAgent extention.
It handle 'If-Modified-Since' request header with local cache file.
local cache files are implemented by Cache::FileCache. 

=head1 METHODS

TBD.

=head1 SEE ALSO

L<LWP::UserAgent>, L<Cache::Cache>, L<Cache::FileCache>

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@qootas.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
