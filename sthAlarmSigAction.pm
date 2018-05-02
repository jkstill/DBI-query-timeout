
package sthAlarmSigAction;

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
use Sys::SigAction qw( set_sig_handler );

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

	my ($dbh, $sql ) = @_;
	my $sth = $dbh->prepare($sql);
	my $oldaction;

	# timeout on prepare
	eval {
		
		my $code=sub {
			die "Timed out on SQL prepare\n";
		};

		my $h = set_sig_handler(
			'ALRM',
			sub {
				$sth->cancel(); 
				#dont die (oracle spills its guts)
				die "SQL Prepare timed out\n";
			},
			{ mask=>[ qw( INT ALRM ) ] ,safe => 0 } 
		);

		eval {
			alarm($alarmTime);
			$sth = $dbh->prepare($sql);
			alarm(0);
			print "Statement Handle successfully prepared\n";
		};

		alarm(0);

		die "$@\n" if $@;

	};

	if ($@) {
		eval { 
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->disconnect; 
		};
		die "SQL Prepare Timed Out - Sorry!\n";
	}

	# timeout on execute
	eval {
		my $code=sub {
			die "Timed out on SQL execute\n";
		};

		my $h = set_sig_handler(
			'ALRM',
			sub {
				$sth->cancel(); 
				#dont die (oracle spills its guts)
				die "SQL Execution timed out\n";
			},
			{ mask=>[ qw( INT ALRM ) ] ,safe => 0 } 
		);

		eval {
			alarm($alarmTime);
			$sth->execute ;
			alarm(0);
			print "Statement Handle successfully executed\n";
		};

		alarm(0);

		die "$@\n" if $@;

	};

	if ($@) {
		eval { 
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->disconnect; 
		};
		die "SQL Execute Timed Out - Sorry!\n" if $@;
	}


	my $handle = bless $sth, $class;
	return $handle;
	
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

	print "Statement Handle successfully processed\n";

	print "Error: $@\n" if $@;
	die "$@\n" if $@;

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


