func cfibexit(termstat)
	dec
		var _xt_pid   : 8;
		var _recbytes : 8;	
	enddec

	sc_sigctl("(");
	voslog("enter-cfibexit task # " &_xt_pid);

	_xt_pid   = getpid();
	_recbytes = procread("recbytes",_xt_pid); 

	sc_clrdigits(line);

	procwrit("runtime",tmr_secs());

	switch(1)
		case _recbytes > FULLREC_LEN:
			procwrit("termstat","FULLREC");
		case _recbytes > SHORTREC_LEN:
	  		procwrit("termstat","SHORTREC");
		case _recbytes > MINREC_LEN:
			procwrit("termstat","MINREC");
		default:
			procwrit("termstat","RECHUP");
	endswitch	
	
	logterm();

	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);

	clrsig(1,line);		
	notify("inbound");
	clrproc(_xt_pid);

	voslog("exit-cfibexit task # " &_xt_pid);
	restart;

	sc_sigctl("c");

endfunc



