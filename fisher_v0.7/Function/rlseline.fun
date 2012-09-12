

func rlseline(_release_line_arg1)

	dec
		var _rl_ret : 2;
	enddec
	voslog("Releasing line " & _release_line_arg1);
	breakpt[1] = "release_line";
	msg_put(1,"release");
	_rl_ret = msg_get(60);
		
	DTI_clrtrans(1, _release_line_arg1);
	clrsig(1, _release_line_arg1);
	return(_rl_ret);

endfunc

