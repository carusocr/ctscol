
func dtmfresp(line,prompt,maxd)

     dec
	var resp: 20;
     enddec

     resp = -1;
     sc_sigctl("(");
     sc_clrdigits(line);
     sc_toneint(line,1);
     sc_play(line, prompt, PBMODE);
     sc_getdigits(line,maxd);
     resp = strstrip(strstrip(sc_digits(line),"#"),"*");
     sc_clrdigits(line);
     sc_toneint(line,0);	
     sc_sigctl(")");
     return(resp);

endfunc


