func cfibexit(termstat)
	dec
		var _xt_pid : 8;	
	enddec

	_xt_pid = getpid();

	voslog("enter-cfibexit task # " &_xt_pid);
	sc_sigctl("(");
	sc_clrdigits(line);

	procwrit("runtime",tmr_secs());

	if(procread("termstat",_xt_pid) eq "BRIDGED")
		switch(1)
		case procread("recbytes",_xt_pid) > FULLREC_LEN:
			procwrit("termstat","FULLREC");
		case procread("recbytes",_xt_pid) > SHORTREC_LEN:
	  		procwrit("termstat","SHORTREC");
		case procread("recbytes",_xt_pid) > MINREC_LEN:
			procwrit("termstat","MINREC");
		default:
			procwrit("termstat","RECHUP");
		endswitch	
	endif
	
	logterm();
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	clrsig(1,line);		
	notify("inbound");
	clrproc(_xt_pid);

	sc_sigctl("c");
	voslog("exit-cfibexit task # " &_xt_pid);
	restart;
endfunc

