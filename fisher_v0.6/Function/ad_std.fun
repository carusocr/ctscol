
func ad_std(pid, currad)

     dec
	var _rtn : 2;
     enddec

     shell_wait(DNISTEST & " -p " & pid & " -t " & currad,"-");
     _rtn = procread("dnistest_resp",pid);
     return(_rtn);

endfunc

