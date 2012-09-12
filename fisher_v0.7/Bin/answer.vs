dec
	include "fisher_core.inc"
	include "fisher_common.inc"
	include "fisher_perl.inc"
	include "cfib_recparm.inc"
	include "cfib_perl.inc"
	include "fisher_prompts.inc"
	include "tone_prompts.inc"
	include "cfib_prompts.inc"
	include "dnis_opts.inc"
	var adinfo : 25;
	var ani : 20;
	var number : 20;
	var dnis : 8;
 	var lang : 3;

enddec

program	

	msg_settaskname("answerT" & getpid());	
      	msg_flush();	
	ro_pid = getpid();
	clrproc(ro_pid);
	line = arg(1);

	if(line < MIN_SLOTNR or line > MAX_SLOTNR)
		voslog("Critical Error: Failed to get line: invalid lineid: " & line);
		restart;
	endif
	
	glb_set(ro_pid,"WAIT");

	procwrit("line",line);

	notify("inbound");

	scb_route(DTI_BOARD*DTI_OFFSET + line,SCB_DTI,line,SCB_VOX,SCB_FULL_DUPLEX);

	DTI_clrsig(DTI_BOARD,line,3);

	DTI_clrtrans(DTI_BOARD,line);

	DTI_watch(DTI_BOARD,line,"Aa");

	DTI_use(DTI_BOARD,line,"a");
	do
		DTI_wait(DTI_BOARD,line);
	until(DTI_trans(DTI_BOARD,line,"A"));
	voslog("wink on line " & line);
	glb_set(ro_pid,"WINK");

	DTI_wink(DTI_BOARD,line);

	do
	until(sc_stat(line,4) >= MAX_ANIDNIS_LEN and sc_stat(line,10) eq 0);

	sc_getdigits(line,MAX_ANIDNIS_LEN);
	
	adinfo = sc_digits(line);

	DTI_setsig(DTI_BOARD,line, 3);	
	sc_playtone(line,400,450,-10,-10,100);	

	if(length(adinfo) < MAX_ANIDNIS_LEN)
		sc_getdigits(line, MAX_ANIDNIS_LEN);
		adinfo = adinfo & sc_digits(line);
	endif

	voslog("ADinfo for line " & line & ": " & adinfo);
	ani = substr(adinfo,2,10);
	number = ani;
	dnis = substr(adinfo,13,4);

	glb_set(ro_pid,"DN" & substr(dnis,3,2));

	if(rejlist(ani) eq FALSE)
		switch(dnis)
		case DNIS_A:
			lang = ENG;
			fshib(line,ani,PROJ_SRE12);
		case DNIS_B:
			lang = TON;
			fshib(line,ani,PROJ_SRE12);
		case DNIS_C:
			lang = TON;
			fshib(line,ani,PROJ_SRE12);
		default:
			sc_getdigits(line, MAX_ANIDNIS_LEN);
			sc_clrdigits(line);
		endswitch	
	else
		sc_clrdigits(line);
	endif

	notify("inbound");
	DTI_clrsig(DTI_BOARD, line, 3);
	glb_set(ro_pid,"RESTART");
	restart;

endprogram

func rejlist(_test_ani)
	dec
		var _isblacklisted: 1;
		var _fh : 8;
	enddec
	_isblacklisted = FALSE;
	_fh = fil_open(BLACKLIST_FILE, "rs");
	while(not fil_eof(_fh))
		if(fil_getline(_fh) streq _test_ani)
			_isblacklisted = TRUE;
			break;
		endif
	endwhile
	fil_close(_fh);
	_fh = "-1";
	return(_isblacklisted);	
endfunc

func gen_commname(_gc_arg1)
	dec
		var _gc_fname : 80; 
	enddec
	
	if(_gc_arg1 streq "A")
		_gc_fname = FSH_COMMENTS & date(1) & "_" & time() & "_" & pin & "_" & mypair_pin & "_" & _gc_arg1 & ".ul";
	else
		_gc_fname = FSH_COMMENTS & date(1) & "_" & time() & "_" & mypair_pin & "_" & pin & "_" & _gc_arg1 & ".ul";
	endif
	voslog("for comments using " & _gc_fname);
	return(_gc_fname);
endfunc
onsignal
	

	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);

	glb_set(ro_pid,"HUP");
	sc_sigctl("c");

	switch(dnis)
	case DNIS_A:
		fsh_exit(5,0,0,TRUE,ANSRMODE);			
	case DNIS_B:
		notify("inbound");
		DTI_clrsig(DTI_BOARD,line,3);
		restart;
	case DNIS_C:
		if(procexst("ce_pid",ro_pid) and glb_get(procread("ce_pid",ro_pid)) strneq "HUP")
			sc_hangup(procread("ce_line",ro_pid));
		endif		
		cfibexit(procread("termstat",ro_pid));
	default:
		notify("inbound");
		DTI_clrsig(DTI_BOARD,line,3);
		restart;
	endswitch
end

func procexists(_fpr_fil,_fpr_pid)
        dec

        enddec
	voslog("entret-procexists task # " & ro_pid);
        if(fil_info(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,1) > 0)
                return(TRUE);
        else
          return(FALSE);
        endif

endfunc

