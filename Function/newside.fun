
func newside(proj,number,line,pid)
	dec
		var _cmd   : 90;
		var _nsscr : 90;
		var _rtn   : 64; 
	enddec
	voslog("entret-newside task # " & pid);

	_rtn = -1;

	switch(proj)
	case PROJ_CFIB:
		_nsscr = CFIB_NEWSIDE;
	case PROJ_FSHSPA:
		_nsscr = FSHSPA_NEWSIDE;
	case PROJ_FSHENG:
		_nsscr = FSHENG_NEWSIDE;
	case PROJ_SRE12:
		_nsscr = SRE12_NEWSIDE;
	case PROJ_MX3:
                _nsscr = MX3_NEWSIDE;
	default:
		voslog("newside error : no such project " & proj);
	endswitch

	if(_nsscr)
		_cmd = _nsscr & " " & number & " " & line & " " & pid;
		voslog(_cmd);
		shell_wait(_cmd,"-");
		_rtn = procread( "newside_resp", getpid() ); 
	endif

        return(_rtn);

endfunc

