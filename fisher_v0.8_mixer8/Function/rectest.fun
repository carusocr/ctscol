
func rectest(line,pid)

	dec
		var _rectest : 80;
		var _ret     :  2;
		var _recsize :  6;
		var _code    :  8;

	enddec


	_ret = -1;
	_rectest = "c:\vos_record\spkrid\rectest\" & date(1) & "_" & time() & "_RTP" & pid  & ".ul";

	sc_toneint(line,0);

	_code = sc_record(line, _rectest, 10, 0, 1792, 0);

	if(_code >= 0)

		_recsize = fil_info(_rectest, 1);		
		if(_recsize >= 70000)
			_ret = 1;
			vid_cur_pos(8, pid);
			vid_set_attr(14, 5);			
			vid_print(_code);

			fil_delete(_rectest);
		else
			voslog("DLGC Voice Term Code: " & _code & " rectest ERR filesize error: " & _recsize);
			vid_cur_pos(8, pid);
			vid_set_attr(14,4);			
			vid_print(_code);

		endif		
	else
		voslog("DLGC Voice Error Code: " & _code);
		vid_cur_pos(8, pid);
		vid_set_attr(14,1);			
		vid_print(_code);
	endif
	
	sc_toneint(line,1);
	
	return(_ret);

endfunc




