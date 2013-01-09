func clrproc(pid)	
	voslog("enter-clrproc task # " & pid);
	voslog(CFIB_CLRPROC & " " & pid);
	shell_wait(CFIB_CLRPROC & " " & pid,"-");
	voslog("exit-clrproc task # " & pid);
endfunc
