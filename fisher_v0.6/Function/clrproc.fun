func clrproc(pid)	
	voslog("enter-clrproc task # " &getpid());
	voslog(CFIB_CLRPROC & " " & pid);
	shell_wait(CFIB_CLRPROC & " " & pid,"-");
	voslog("exit-clrproc task # " &getpid());
endfunc
