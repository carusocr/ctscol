
func procread(_fpr_fil,_fpr_pid)

	dec
		var _fpr_ret : 90;
		var _fpr_fh : 4;
	enddec

	if(fil_info(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,1) > 0)
		_fpr_fh = fil_open(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,"rs");
		_fpr_ret = fil_getline(_fpr_fh);
		fil_close(_fpr_fh);
	else
		_fpr_ret = -1;
	endif
	return(_fpr_ret);

endfunc

