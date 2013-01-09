
# arg1 external validate script
# arg2 pin to check
# arg3 phone number to check

func validate(_fi_va_arg1,_fi_va_arg2,_fi_va_arg3)
	voslog("entret-validate task # " &getpid());
	shell_wait(_fi_va_arg1 & " " & getpid() & " " & _fi_va_arg2 & " " &_fi_va_arg3,"-");
	return(procread("validate_resp",getpid()));	
endfunc
