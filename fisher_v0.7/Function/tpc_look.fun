
func tpc_look(_topic,_lang)
	dec
		var _prret : 80;
		var _prtop : 12;
	enddec
	
	_prtop = strstrip(_topic,"/");
	
	
	switch(_lang)
	case ENG:
		_prret = EN_TOPICS & _prtop;
	case SPA:
		_prret = SP_TOPICS & _prtop;
	endswitch

	voslog("TOPIC: " & _prret);
	return(_prret);

endfunc

