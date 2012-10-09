
func cr_query(_qry_line,_qry_prpt,_qry_valid)

	dec
		var _qry_ret : 2;
		var _qry_dig : 2;
		var _qry_itr : 2;
		var _qry_ctr : 2;
	enddec

	for(_qry_ctr = 0;_qry_ctr <=2;++_qry_ctr)

		sc_toneint(_qry_line,1);
		sc_play(_qry_line,_qry_prpt,768);
		sc_toneint(_qry_line,0);
		sc_getdigits(_qry_line,1,60,0);	
		_qry_dig = sc_digits(_qry_line);
		sc_clrdigits(_qry_line);

		_qry_ret = -1;

		for(_qry_itr = 1;_qry_itr <= length(_qry_valid);++_qry_itr)
			if(_qry_dig eq substr(_qry_valid,_qry_itr,1)) 
				_qry_ret = _qry_dig;
				break;
			endif
		endfor

		if(_qry_ret eq -1)
			sc_play(_qry_line,pr_look(INVALID,lang),768);
		else
			break;
		endif
	endfor

	return(_qry_ret);

endfunc

