
func stoprec(arg1)
	
	dec
		var _line : 2;
	enddec

	_line = arg1;
	if(_line > 0)
		if(sc_stat(_line) eq 1)
			sc_abort(_line);
			do
				sleep(1);
			until(sc_stat(line) <> 1);
		endif
	endif


endfunc

