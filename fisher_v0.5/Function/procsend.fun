func procsend(_fps_fil,_fps_ins,_fps_pid)

        dec
		var _fps_ret : 2;	
		var _fps_fh  : 8;
        enddec

	_fps_ret = -1;

	_fps_fh = fil_open(PROC & rjust(_fps_pid,0,2) & "\" & _fps_fil,"trwsc");

	if(_fps_fh >= 0)
		_fps_ret = fil_putline(_fps_fh,_fps_ins);
		fil_close(_fps_fh);

		if(_fps_ret < 0)
			voslog("PROCSEND ERROR: " & _fps_ret);
		endif

	else
		voslog("PROCSEND ERROR: " & _fps_fh);
	endif

	return(_fps_ret);

endfunc
