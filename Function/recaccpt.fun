
func recaccpt(line,lang)
     dec
	var _rtn : 2;
	var _err : 2;
	var _dig : 2;
     enddec

     _rtn = -1;
     _err = 0;

     sc_toneint(line,1);

     while(_err < 3)
	sc_play(line,pr_look(RECNOTIFY,lang), PBMODE);
	sc_play(line,pr_look(RECACCEPT,lang), PBMODE);
	sc_getdigits(line,1,30,0);	
	_dig = sc_digits(line);
	sc_clrdigits(line);

	switch(_dig + 0)
	case 1:
	     _rtn = FSH_RECACCEPT;
	     sc_play(line,pr_look(THANKYOU,lang), PBMODE);
	     break;
	case 9:
             _rtn = FSH_RECREJECT;
	     sc_play(line,pr_look(GOODBYE,lang), PBMODE);
	     break;
	default:
             _rtn = -1;
             sc_play(line,pr_look(INVALID,lang), PBMODE);
	endswitch
     endwhile

     return(_rtn);

endfunc