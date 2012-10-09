
func gettod()
	shell_wait(FSH_GETTOD & " " & getpid(),"-");
	return(TRUE);
endfunc

