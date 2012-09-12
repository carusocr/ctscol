
func recname(line,pin)

	dec
		var _recfile : 80;
		var _ctr     :  1;
		var _code    :  2;
	enddec

	for(_ctr = 0;_ctr < 4;++_ctr)
		_recfile = date(1) & "_" & time() & "_PIN" & pin  & ".ul";
		vid_write("Recording subject name: " & _recfile);

		sc_toneint(line,0);

		# we would like to get a sample of your voice for future reference 
		sc_play(line,pr_look(RECORDNAME,lang),PBMODE);	

		# Please state your name after the tone
		sc_play(line,pr_look(STATENAME,lang),PBMODE);
		
		# sc_record(line,filename,secs,sil,mode,beep)

		_code = sc_record(line,FSH_NAMEREC & _recfile, 6, 2, 1792, 7);
	
		voslog("sc_record retcode: " & _code);

		sc_clrdigits(line);

		## "Your name was recorded as: "
		sc_play(line,pr_look(RECDNAME,lang),PBMODE);
		sc_play(line,FSH_NAMEREC & _recfile, PBMODE);

		sc_toneint(line,1);

		## "If this is acceptable Please press 1. To Rerecord, Press 2.
		switch(cr_query(line,pr_look(RECORDOKYN,lang),"1234567890#*"))
		case 1:
			sc_clrdigits(line);
			sc_play(line,pr_look(THANKYOU,lang),PBMODE);
			break;
		case 2:
			sc_clrdigits(line);
			###fil_delete(_recfile);
		default:
			sc_clrdigits(line);
			sc_play(line,pr_look(INVALID,lang),PBMODE);
		endswitch
	endfor
	return(_recfile);
endfunc




