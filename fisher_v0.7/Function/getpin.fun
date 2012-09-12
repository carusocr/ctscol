
func getpin()

	dec
		var _test_ret  : 8;
                var _gp_line   : 2;
		var _gp_return : 1;
	enddec

	voslog("entret-getpin task # " &getpid());
        _gp_line = procread("line",getpid());

        sc_toneint(_gp_line,0,"#");
	sc_getdigits(_gp_line,6,60,0);
	_test_ret = sc_digits(_gp_line);
        sc_clrdigits(_gp_line);
        sc_toneint(_gp_line, 0);
	_test_ret = strstrip(strstrip(_test_ret,"#"),"*");
	voslog("getpin: " & _test_ret);
	_gp_return = FALSE;	
	if(_test_ret > 0)
		procwrit("pin",_test_ret);
		_gp_return = TRUE;
	endif
	return(_gp_return);

endfunc

