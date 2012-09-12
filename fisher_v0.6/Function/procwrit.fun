func procwrit(_fpw_fil,_fpw_ins)

        dec
		var _fpw_ret : 2;	
		var _fpw_fh  : 8;
        enddec

	_fpw_ret = -1;

	_fpw_fh = fil_open(PROC & rjust(getpid(),0,2) & "\" & _fpw_fil,"trwsc");

	if(_fpw_fh >= 0)
		_fpw_ret = fil_putline(_fpw_fh,_fpw_ins);
		fil_close(_fpw_fh);

		if(_fpw_ret < 0)
			voslog("PROCWRIT ERROR: " & _fpw_ret);
		endif

	else
		voslog("PROCWRIT ERROR: " & _fpw_fh);
	endif

	return(_fpw_ret);

endfunc
