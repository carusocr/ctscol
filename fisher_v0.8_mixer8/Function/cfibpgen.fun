
func cfibpgen(line,pid)

     dec
     
	const PGEN_NEWPIN = "2";
	const PGEN_CONTINUE = "1";
	const PGEN_INVALID_FAIL = "-1";
        var ntries : 2;
        var pgret : 2;
	var preqresp : 6;
	var pinreq_yn : 2;
	var ce_gend : 2;
	var ce_phnum : 16;
	var ce_nick : 25;

     enddec     

     for(ntries = 0; ntries < 3; ++ntries)

	pinreq_yn = dtmfresp(line, CFIB_PINREQ, 1);
     	switch(pinreq_yn)
     	case 1:

	  sc_toneint(line,0);
	  sc_play(line, CFIB_PINREQ_PHNUM, PBMODE);
	  sc_toneint(line,0,"#*");
	  sc_getdigits(line, 15, 20, 5);
	  ce_phnum = strstrip(strstrip(sc_digits(line),"#"),"*");
	  sc_clrdigits(line);
	  
	  sc_toneint(line,0);
	  ce_gend  = dtmfresp(line,CFIB_PINREQ_GEND, 1);

	  procwrit("ce_phnum", ce_phnum);
	  procwrit("ce_number", ce_phnum);
	  procwrit("ce_gend",  ce_gend);

	  voslog(CFIB_PGENREQ & " -p " & pid & " -g " & ce_gend);

	  shell_wait(CFIB_PGENREQ & " -p " & pid & " -g " & ce_gend,"-");

	  ce_nick  = procread("ce_nick",  pid);
	  preqresp = procread("preqresp", pid);

	  voslog("PREQRESP " & preqresp);
	  do
		sc_play(line, CFIB_PINREQ_SUCCESS, PBMODE);
	  	digiplay(line, preqresp);
	  until(dtmfresp(line,CFIB_PINREQ_REPEAT,1) <> 1);

	  pgret = PGEN_NEWPIN;	  
	  break;
     	case 2:	  
	  pgret = PGEN_CONTINUE;
     	  break;
     	default:
	  pgret = PGEN_INVALID_FAIL;
	  sc_play(line, CFIB_INVALIDRESP, PBMODE);
     	endswitch
     endfor
     
     return(pgret);

endfunc