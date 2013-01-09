# arg1 external perl script
# arg2 arguments for perl script as csv

func runperl(arg1,arg2)
	voslog("entret-runperl task # " &getpid());
	shell_wait(arg1 & " " & arg2,"-");
	return(procread("runperl_resp",getpid()));	
endfunc
