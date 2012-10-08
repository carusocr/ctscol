
func fsplog(side_id,value,dbfield)

	dec
		var _cmd : 120;
	enddec

	_cmd = PERL_LOGVAL & " " & side_id & " " & value & " " & dbfield;
	return(shell_wait(_cmd,"-"));

endfunc


