

func clrsig(_fc_board,_fc_line)
	
	if(_fc_board >= MIN_BOARDNR and _fc_board <= MAX_BOARDNR)
		if(_fc_line >= MIN_SLOTNR and _fc_line <= MAX_SLOTNR)
			DTI_clrtrans(_fc_board,_fc_line);
			do
				DTI_clrsig(_fc_board,_fc_line,3);
				sleep(1);
			until(DTI_getsig(_fc_board,_fc_line) streq "0000");
		else
			voslog("Invalid Slot Nr: " & _fc_line);
		endif
	else
		voslog("Invalid Board Nr: " & _fc_board);
	endif	

endfunc


