
func ibtest(line,dnis,number)
	
	dec
		var _i   : 1;
		var _ctr : 1;
	enddec

	for(_i = 0;_i < 3;++_i)
                sc_play(line,"d:\fisher_v0.5\Prompts\current\breakmsg.ul",768);

        	#for(_ctr = 1;_ctr <= length(dnis);++_ctr)
                #	sc_play(line,"d:\fisher_v0.5\Prompts\current\NC000" & substr(dnis,_ctr,1) & "ENG.ul",768);
        	#endfor

        	#for(_ctr = 1;_ctr <= length(number);++_ctr)
                #	sc_play(line,"d:\fisher_v0.5\Prompts\current\NC000" & substr(number,_ctr,1) & "ENG.ul",768);
        	#endfor

        endfor

	clrsig(1,line);
	notify("inbound");
	clrproc(getpid()); 
        restart;

endfunc