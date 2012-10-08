func delproc(pid)	

	shell_wait(CFIB_DELPROC & " " & pid,"-");

endfunc
