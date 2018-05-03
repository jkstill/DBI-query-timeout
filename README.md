
# DBI Query Timeout

Demos of timing out a query in DBI

There are at least a couple of modules that can be used as the basis for using an alarm to timemout a query:

  * POSIX qw(:signal_h)
  * Sys::SigAction qw( set_sig_handler )

Each method is demostrated

# POSIX

This is probably the preferred method simply due to POSIX being included with the Perl distribution.

Both of the following modules are classed from the DBI module.

Neither are really complete as to the handling of inputs and return types, but can serve as the basis for building something more robust

Each will time out on preparation and execution of statment handles.

The demo scripts to rely on a function of Oracle 12.1 that allows executing a pl/sql function directly from SQL

## sthAlarmPosix.pm

The following two scripts demonstrate the use of this module

The alarm time in seconds is currently hardcode near the top of the file

  our $alarmTime = 3; # seconds


### sth-timeout-posix.pl

Given a statement to execute, timeout if the prepare() or execute() takes longer than N seconds the script will time out.

example

```bash
server> ~/oracle/DBI-query-timeout $

Connected to p1 as scott

Statement Handle successfully created
Statement Handle successfully executed
2.00
server>  ~/oracle/DBI-query-timeout $
>

>  ./sth-timeout-posix.pl 4

Connected to p1 as scott

Statement Handle successfully created
SQL Execute Timed Out - Sorry!

```

### sth-timeout-posix-multi.pl

This script demonstrates how to work through a set of values and execute the query for each.
If the query times out a new connection must be made.


```bash
server> ~/oracle/DBI-query-timeout $
>  ./sth-timeout-posix-multi.pl

Connected to p1 as jkstill

Statement Handle successfully created
Statement Handle successfully executed
                   0.00
Statement Handle successfully created
Statement Handle successfully executed
                   1.00
Statement Handle successfully created
Statement Handle successfully executed
                   2.00
Statement Handle successfully created
Statement Handle successfully executed
                   3.00
Statement Handle successfully created
Timed out on values: 4
Statement Handle successfully created
Timed out on values: 5
```


## sthAlarmSigAction.pm

This is an alternate method for timing out a query.

### sth-timeout-sigaction.pl

```bash
>server ~/oracle/DBI-query-timeout $
>  ./sth-timeout-sigaction.pl 2

Connected to p1 as scott

Statement Handle successfully prepared
Statement Handle successfully executed
Statement Handle successfully processed
                   2.00
Statement Handle successfully processed
jkstill@poirot ~/oracle/DBI-query-timeout $
>
jkstill@poirot ~/oracle/DBI-query-timeout $
>  ./sth-timeout-sigaction.pl 4

Connected to p1 as scott

Statement Handle successfully prepared
SQL Execute Timed Out - Sorry!
```



