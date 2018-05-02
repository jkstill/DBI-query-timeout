
package sthAlarmPosix;

our $VERSION = '0.01';

require DBI;

@ISA=qw(DBI DBI::db DBI::st);

#use DBI;
use Carp;
use strict;
no strict 'refs';
use warnings;
#use diagnostics;
use Data::Dumper;
use POSIX qw(:signal_h);

our $alarmTime = 3; # seconds

=head1 new

create a new statement handle in preparation
for retrieving data

example:

   my $vobj = new sthAlarm($dbh, $sql);
   die "object creation failed \n" unless $vobj;
	
	instantiate a new V$ table object.  

	an optional WHERE clause and ORDER BY clause
	may be specified as well


=cut

sub new {

	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my ($dbh, $sql, @binds ) = @_;
	#print "SQL: $sql\n";
	#print "binds: ", join(' - ',@binds),"\n";
	#print "bind 0: $binds[0]\n";
	# silly workaround for apparent bug
	$sql =~ s/\?/$binds[0]/;
	my $sth = $dbh->prepare($sql);
	my $oldaction;

	# timeout on prepare
	eval {
		my $mask = POSIX::SigSet->new( SIGALRM );
		my $code=sub {
			die "Timed out on SQL prepare\n";
		};
		my $action =  POSIX::SigAction->new(
			$code,
			$mask
		);

		$oldaction = POSIX::SigAction->new();
		sigaction( SIGALRM, $action, $oldaction );

		eval {
			POSIX::alarm($alarmTime);
			$sth = $dbh->prepare($sql);
			POSIX::alarm(0);
			croak "Failed to prepare $sql - $dbh->errstr\n" unless $sth;
			print "Statement Handle successfully created\n";
		};

		POSIX::alarm(0);
		sigaction( SIGALRM, $oldaction );  # restore original signal handler

		die "$@\n" if $@;

	};

	if ($@) {
		$sth->finish;
		$dbh->disconnect;
		die "SQL Prepare Timed Out - Sorry!\n";
	}

	# timeout on execute
	eval {
		my $mask = POSIX::SigSet->new( SIGALRM );
		my $code=sub {
			die "Timed out on SQL execute\n";
		};
		my $action =  POSIX::SigAction->new(
			$code,
			$mask
		);

		$oldaction = POSIX::SigAction->new();
		sigaction( SIGALRM, $action, $oldaction );

		eval {
			POSIX::alarm($alarmTime);
			#if ( $#binds >= 0) {
			#$sth->execute(@binds) ;
			#} else {
				$sth->execute ;
				#}
			POSIX::alarm(0);
			print "Statement Handle successfully executed\n";
		};

		POSIX::alarm(0);
		sigaction( SIGALRM, $oldaction );  # restore original signal handler

		die "$@\n" if $@;

	};

	if ($@) {
		$sth->finish;
		eval { 
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->disconnect; 
		};
		die "SQL Execute Timed Out - Sorry!\n" if $@;
	}


	my $handle = bless $sth, $class;
	#my $handle = bless \%args, $class;
	return $handle;
	
}

sub reconnect {
	my $self = shift;
	#print Dumper(\$self);
}


=head1 next

retrieve the next row of data and return
in a hash via reference

can return either a hashref or an arrayref

default is hashref

example:

   while( my $row = $vobj->next ) {
      print "SID: $row->{sid}\n";
   }

   while( my $row = $vobj->next([]) ) {
      print "SID: $row->[0]\n";
   }

=cut



sub next {
	my $self = shift;
	my ( $ref ) = @_;
	$ref ||= {};

	my $refType = ref $ref;
	my $data;

	if ( 'ARRAY' eq $refType ) {
		$data = $self->fetchrow_arrayref;
	} elsif ( 'HASH' eq $refType ) {
		$data = $self->fetchrow_hashref;
	} else { croak "invalid ref type of $refType used to call PDBA::GQ->next\n" }


	if ( ! defined($data) ) { 
		return undef;
	}

	return $data;
}

=head1 all

return all rows into a hashref

See the getColumns entry for an example

see DBI::fetchall_arrayref for info on this

=cut

sub all {
	my $self = shift;

	my ( $ref ) = @_;
	$ref ||= {};
 
	my $refType = ref $ref;
 
	my $array;
	if ( 'ARRAY' eq $refType ) {
		$array = $self->fetchall_arrayref([]);
	} elsif ( 'HASH' eq $refType ) {
		$array = $self->fetchall_arrayref({});
	} else { croak "invalid ref type of $refType used to call PDBA::GQ->all\n" }

	if ( ! defined($array) ) { 
		return undef;
	}
	return $array;
}


sub finiah {
	my $self = shift;
	$self->finiah;
}


