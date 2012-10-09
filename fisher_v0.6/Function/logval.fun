
func logval(side_id,value,dbfield)
	dec
		var _cmd : 90;
	enddec
	voslog("entret-logval task # " &getpid());
	voslog(side_id & " " & value & " " & dbfield);
	_cmd = CFIB_LOGVAL & " " & side_id & " " & value & " " & dbfield;
	voslog(_cmd);
	return(shell_wait(CFIB_LOGVAL & " " & side_id & " " & value & " " & dbfield,"-"));

endfunc


