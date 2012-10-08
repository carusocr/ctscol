
func ibtest(line,dnis,number)
	
	dec
		var _i   : 1;
		var _ctr : 1;
	enddec

	for(_i = 0;_i < 3;++_i)
                sc_play(line,"d:\fisher_v0.5\Prompts\current\breakmsg.ul",768);
        endfor

	clrsig(1,line);
	notify("inbound");
	clrproc(getpid()); 
        restart;

endfunc

