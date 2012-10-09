
func namelook(_pin)
	dec
		var _ret : 80;
	enddec

	switch(1)
	case fil_info(NAMEPRPT &  _pin & ".ul",1) > 0:
		_ret = NAMEPRPT & _pin & ".ul";
	case fil_info(NAMEPRPT & get_pinfname(_pin) & ".ul",1) > 0:
		_ret = NAMEPRPT & get_pinfname(_pin) & ".ul";
	default:
		_ret = NAMEPRPT & "default.ul";
	endswitch

	voslog("NAME: " & _ret);
	return(_ret);

endfunc

