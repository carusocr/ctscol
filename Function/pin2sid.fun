
func pin2sid(_ps_pin,_ps_pid)
	shell_wait(CFIB_PIN2SID & " " & _ps_pid & " " & _ps_pin,"-");
	return(procread("ce_subj_id",_ps_pid));
endfunc

