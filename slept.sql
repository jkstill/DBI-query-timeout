with
	function sleep (sleep_time_in number) return varchar2
	is
	begin
		dbms_lock.sleep(sleep_time_in);
 	 	return to_char(sleep_time_in, '990.90');
	end;
select sleep(.25) slept from dual
/
