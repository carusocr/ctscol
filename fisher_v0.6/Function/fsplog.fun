
func fsplog(side_id,value,dbfield)

	dec
		var _cmd : 120;
	enddec
	voslog("entret-logval task # " &getpid());
	_cmd = FSHSPA_LOGVAL & " " & side_id & " " & value & " " & dbfield;
	voslog(_cmd);
	return(shell_wait(_cmd,"-"));

endfunc


