#!/usr/bin/env perl


use Data::Dumper;
use DBI;
use warnings;
use strict;

use lib qw{./};
use sthAlarmSigAction;


my $sleepTime = $ARGV[0];

$sleepTime = 1 unless $sleepTime;

my($db, $username, $password, $connectionMode);

$connectionMode = 0;
$db='p1';
$username='scott';
$password='tiger';

my $dbh = DBI->connect(
	'dbi:Oracle:' . $db, 
	$username, $password, 
	{ 
		RaiseError => 1, 
		AutoCommit => 0,
		ora_session_mode => $connectionMode
	} 
	);

die "Connect to  $db failed \n" unless $dbh;

print "\nConnected to $db as $username\n\n";

# apparently not a database handle attribute
# but IS a prepare handle attribute
#$dbh->{ora_check_sql} = 0;
$dbh->{RowCacheSize} = 100;

#my $sql=q{select username from (select username from all_users order by username) where rownum <= 5};

my $sql = qq{with
	function sleep (sleep_time_in number) return varchar2
	is
	begin
		dbms_lock.sleep(sleep_time_in);
 	 	return to_char(sleep_time_in, '990.90');
	end;
select sleep($sleepTime) slept from dual};

# my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

my $sthObj = new sthAlarmSigAction($dbh,$sql);

# get a hash ref - default
while( my $row = $sthObj->next ) {
	print "\t\t$row->{SLEPT}\n";
}


$sthObj->finish;

#$sthObj->reconnect;

$dbh->disconnect;




