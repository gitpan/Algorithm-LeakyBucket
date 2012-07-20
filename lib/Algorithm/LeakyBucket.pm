package Algorithm::LeakyBucket;

=head1 NAME

Algorithm::LeakyBucket - Perl implementation of leaky bucket rate limiting

=head1 SYNOPSIS

 use Bucket::Leaky;
 my $bucket = Bucket::Leacky->new( ticks => 1, seconds => 1 ); # one per second

 while($something_happening)
 {
     if ($bucket->tick)
     {
         # allowed
         do_something();
     }
 }

=head1 DESCRIPTION

Implements leaky bucket as a rate limiter.  If you pass memcached options it will also use memcached.
If the memcached servers are not availble it falls back to the local counters.

This version uses Cache::Memcached::Fast

 my $bucket = Bucket::Leaky->new( ticks => $ticks, seconds => $every_x_seconds,
                                  memcached_key => 'some_key',
                                  memcached_servers => [ { address => 'localhost:11211' } ] );

Multiple instances of the code would all then halt each other from breaking the rate limit. (But see the BUGS section)

This is an early alpha version of the code.  I built this as a rate limiter that I could toss in my
mod_perl implementations to keep some clients from slamming an API.

=cut

use 5.008009;
use strict;
use warnings;
use Carp qw(cluck);
use Cache::Memcached::Fast;
our $VERSION = '0.06';

sub new
{
	my ($class, %args) = @_;
	my $self = {};
	bless ($self, $class);
	while (my($k,$v) = each (%args))
	{
		if ($self->can($k))	
		{	
			$self->$k($v);
		}
	}
	$self->init(%args);


	return $self;
}

sub ticks
{
	my ($self, $value) = @_;
	if (defined($value))
	{
		$self->{__ticks} = $value;
	}
	return $self->{__ticks};
}

sub seconds
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__seconds} = $value;
        }
        return $self->{__seconds};
}

sub current_allowed
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__current_allowed} = $value;
        }
        return $self->{__current_allowed};
}

sub last_tick
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__last_tick} = $value;
        }
        return $self->{__last_tick};
}

sub memcached_key
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__mc_key} = $value;
        }
        return $self->{__mc_key};
}

sub memcached
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__mc} = $value;
        }
        return $self->{__mc};
}

sub memcached_servers
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__mc_servers} = $value;
        }
        return $self->{__mc_servers};
}

sub tick
{
	my ($self, %args ) = @_;

	if ($self->memcached)
	{
		# init form mc 
		$self->mc_sync;
	}
	
	# seconds since last tick
	my $now = time();
	my $seconds_passed = $now - $self->last_tick;
	$self->last_tick( time() );

	# add tokens to bucket
	my $current_ticks_allowed = $self->current_allowed + ( $seconds_passed * ( $self->ticks / $self->seconds ));
	$self->current_allowed( $current_ticks_allowed );

	if ($current_ticks_allowed > $self->ticks)
	{
#		cluck("OK Allowed $current_ticks_allowed, tbucket is full");
		$self->current_allowed($self->ticks);
		if ($self->memcached)
		{
			$self->mc_write;
		}
		return 1;
	}
	elsif ($current_ticks_allowed < 1)
	{
#		cluck("Allowed $current_ticks_allowed -> no");
	}
	else
	{
#		cluck("OK Allowed $current_ticks_allowed, take one away");
		$self->current_allowed( $current_ticks_allowed - 1);
                if ($self->memcached)
                {
                        $self->mc_write;
                }
		return 1;
	}
	
	return;
}

sub init
{
	my ($self, %args) = @_;
	$self->current_allowed( $self->ticks );
	$self->last_tick( time() );
	if ($self->memcached_servers)
	{
		my $mc = Cache::Memcached::Fast->new({ servers => $self->memcached_servers,
						  namespace => 'leaky_bucket:', });
		$self->memcached($mc);
		$self->mc_sync;
	}
	return;
}

sub mc_sync
{
	my ($self, %args) = @_;

	my $packed = $self->memcached->get( $self->memcached_key );
	if ($packed)
	{
		# current allowed | last tick
		my @vals = split(/\|/,$packed);
		$self->current_allowed($vals[0]);
		$self->last_tick($vals[1]);
	}
	return;
}

sub mc_write
{
	my ($self, %args) = @_;
	$self->memcached->set($self->memcached_key, $self->current_allowed . '|' . $self->last_tick);
	return;
}

=head1 BUGS

Probably some.  There is a known bug where if you are in an infinite loop you could move faster than
memcached could be updated remotely, so you'll likely at that point only bbe limted by the local 
counters.  I'm not sure how im going to fix this yet as this is in early development.
 
=head1 SEE ALSO

http://en.wikipedia.org/wiki/Leaky_bucket

=head1 AUTHOR

Marcus Slagle, E<lt>marc.slagle@online-rewards.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Marcus Slagle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;


