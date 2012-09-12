func cfibexit(termstat)
	dec
	
	enddec
	voslog("enter-cfibexit task # " &getpid());
	sc_sigctl("(");
	sc_clrdigits(line);
	procwrit("runtime",tmr_secs());

	if(procread("termstat",getpid()) eq "BRIDGED")
		switch(1)
		case procread("recbytes",getpid()) > FULLREC_LEN:
			procwrit("termstat","FULLREC");
		case procread("recbytes",getpid()) > SHORTREC_LEN:
	  		procwrit("termstat","SHORTREC");
		case procread("recbytes",getpid()) > MINREC_LEN:
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
	clrproc(getpid());

	sc_sigctl("c");
	voslog("exit-cfibexit task # " &getpid());
	restart;
endfunc

