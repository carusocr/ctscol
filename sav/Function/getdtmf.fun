
func getdtmf(arg1,arg2,arg3)

	dec
		var _ret    : 20;
                var _line   : 2;
		var _prompt : 60;
	        var _minlen : 4;
	enddec

        _line = arg1;
	_prompt = arg2;
	_minlen = arg3;
	voslog("entret-getdtmf task # " &getpid());	
        sc_toneint(_line,0,"#");
	sc_play(_line,_prompt, PBMODE);
	sc_getdigits(_line,20,60,0);
	_ret = sc_digits(_line);
        sc_clrdigits(_line);
        sc_toneint(_line, 0);
	_ret = strstrip(strstrip(_ret,"#"),"*");

	voslog("getdtmf entered by caller: " & _ret);
	if(length(_ret) >= _minlen)
		return(_ret);
	else
		return(-1);
	endif

endfunc

