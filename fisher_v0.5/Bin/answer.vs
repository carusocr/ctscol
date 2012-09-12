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
	var dnis : 8;
 	var lang : 3;
	var rec_pid : 4;
enddec

program	

	msg_settaskname("answerT" & getpid());	
      	msg_flush();	
	clrproc(getpid());
	line = arg(1);

	if(line < 1 or line > 48)
		voslog("answer.vs pid: " & getpid() & " : Critical Error: Failed to get line: invalid lineid: " & line);
		restart;
	endif
	
	dboard = 1;
	glb_set(getpid(),"WAIT");

	procwrit("line",line);

	notify("inbound");

	voslog("process-id " & getpid() & " using line " & line & " to wait for a call");
	scb_route(dboard*256 + line,SCB_DTI,line,SCB_VOX,SCB_FULL_DUPLEX);
	DTI_clrsig(dboard,line,3);

	DTI_clrtrans(dboard,line);
	DTI_watch(dboard,line,"Aa");
	DTI_use(dboard,line,"a");
	do
		DTI_wait(dboard,line);
	until(DTI_trans(dboard,line,"A"));
	voslog("wink on line " & line);
	glb_set(getpid(),"WINK");

	DTI_wink(dboard,line);

	do
		sleep(1);
	until(sc_stat(line,4) >= 17 and sc_stat(line,10) eq 0);

	sc_getdigits(line,17);
	
	adinfo = sc_digits(line);

	DTI_setsig(dboard,line, 3);	
	sc_playtone(line,460,455,-10,-10,100);	

	if(length(adinfo) < 17)
		sc_getdigits(line, 17);
		adinfo = adinfo & sc_digits(line);
	endif

	voslog("ADinfo for line " & line & ": " & adinfo);
	ani = substr(adinfo,2,10);
	dnis = substr(adinfo,13,4);

	glb_set(getpid(),"DN" & substr(dnis,3,2));

	vid_cur_pos(10,19);
	vid_set_attr(10,8);
	vid_print("Last IBC: " & ani & " L" & line);
	vid_set_attr(7,0);

	if(rejlist(ani) eq FALSE)
		switch(dnis)
		case DNIS_A:
			lang = ENG;
			fshib(line,ani,PROJ_MX3);
			# ibtest(line,dnis,ani);
		case DNIS_B:
			lang = TON;
			fshib(line,ani,PROJ_MX3);
			# cfib(line,ani);
		case DNIS_C:
			lang = TON;
			fshib(line,ani,PROJ_MX3);
		default:
			sc_getdigits(line, 17);
			voslog("dtmf buffer: " & sc_digits(line));
			sc_clrdigits(line);
			voslog("answer pid: " & getpid() & " : Invalid DNIS - Restarting");
		endswitch	
	else
		voslog("blacklisted ANI: " & ani);
		sc_clrdigits(line);
		voslog("answer.vs pid " & getpid() & " Restarting");
	endif

	# .. process call ..
	# Disconnect call by setting A=B=0
	notify("inbound");
	DTI_clrsig(dboard, line, 3);
	glb_set(getpid(),"RESTART");
	restart;

endprogram

func rejlist(_test_ani)
	dec
		var _isblacklisted: 1;
		var _fh : 8;
	enddec
	_isblacklisted = FALSE;
	_fh = fil_open("d:\fisher_v0.5\Bin\blacklist.txt", "rs");
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

func fsh_exit(_fe_rsdelay,_fe_bpt,_fe_bpref,_fe_onsig)
	dec
		var _fe_rpt: 4;
		var _fe_sutdelta: 8;
	enddec
	voslog("enter-fsh_exit task # " & getpid());
	sc_sigctl("("); #allow exit to finish 
	stoprec(line);	
	stoprec(mypair_line);
	glb_set(getpid(),"HUP");
	if(toh_end eq 0 and toh_start > 0)
		toh_end = tmr_secs();
	endif
	status[TOHTIME] = toh_end - toh_start;

	if(pin_locked eq 1)
		voslog("PIN_LOCKED = 1 - Sending to DB");
		if(DTI_getsig(1,line) streq "1111")
			sc_play(line,pr_look(GOODBYE,lang),PBMODE);
		endif
		
		status[FULLREC] = "no";
		status[SHORTREC] = "no";
		status[NOREC] = "no";
		status[SUCCESS] = "no";

		switch(1)
		case status[FILESIZA] >= 1920000:
			status[FULLREC] = "yes";
			status[SUCCESS] = "yes";
			_fe_sutdelta = "H18";
			procwrit("termstat","FULLREC");
		case status[FILESIZA] > 0 and status[FILESIZA] < 1920000:
			status[SHORTREC] = "yes";
			_fe_sutdelta = "H8";
			procwrit("termstat","SHORTREC");
		case status[FILESIZA] <= 0 and status[POSANSR] streq "yes":
			status[NOREC] = "yes";
			_fe_sutdelta = "H4";
			procwrit("termstat","RECHUP");
		case status[POSANSR] streq "no" and status[TOPREJECT] streq "yes":
			status[NOREC] = "yes";
			_fe_sutdelta = "H18";
			procwrit("termstat","TOPREJECT");
		case status[POSANSR] streq "no" and status[TOPREJECT] strneq "yes":
			status[NOREC] = "yes";
			_fe_sutdelta = "H4"; 	
			procwrit("termstat","HUP");
		default:
			procwrit("termstat","HUP");
			_fe_sutdelta = "H8";
		endswitch

		voslog(_fe_sutdelta & " " & status[POSANSR] & " " & status[FILESIZA]);
		

		_fe_rpt = fil_open(PROC & rjust(getpid(),0,2) & "\final_report","trwc");
		voslog("Using Filehandle " &_fe_rpt);
	
		fil_putline(_fe_rpt,"CALL_ID="      & procread("call_id",getpid()));	
		fil_putline(_fe_rpt,"FILA="         & procread("fnama",getpid()));
		fil_putline(_fe_rpt,"FILB="         & procread("fnamb",getpid()));
		fil_putline(_fe_rpt,"FILESIZA="     & procread("filesiza",getpid()));
		fil_putline(_fe_rpt,"FILESIZB="     & procread("filesizb",getpid()));
		fil_putline(_fe_rpt,"SUBJ_ID="      & procread("cra_subjid",getpid()));
		fil_putline(_fe_rpt,"CE_SUBJ_ID="   & procread("crb_subjid",getpid()));
		fil_putline(_fe_rpt,"CRA_SUBJID="   & procread("cra_subjid",getpid()));
		fil_putline(_fe_rpt,"CRB_SUBJID="   & procread("crb_subjid",getpid()));
		fil_putline(_fe_rpt,"TIMESTAMP="    & date(1) & "_" & time());		
		fil_putline(_fe_rpt,"PIN="          & pin);
		fil_putline(_fe_rpt,"NUMBER="       & ani);
		fil_putline(_fe_rpt,"PAIR="         & mypair_pin);		
		fil_putline(_fe_rpt,"PAIRNUMBER="   & mypair_number);
		fil_putline(_fe_rpt,"MYPHNSET="     & myphnset);
		fil_putline(_fe_rpt,"PAIRPHNSET="   & mypair_phnset);
		fil_putline(_fe_rpt,"MYPHNTYPE="     & myphntype);
		fil_putline(_fe_rpt,"PAIRPHNTYPE="   & mypair_phntype);		
		fil_putline(_fe_rpt,"TOPIC="        & topic);
		fil_putline(_fe_rpt,"TOPIC_ID="     & procread("topic_id",getpid()));
		fil_putline(_fe_rpt,"RECORDING="    & status[RECORDING]);	 		
		fil_putline(_fe_rpt,"RUNTIME="      & status[RUNTIME]);
		fil_putline(_fe_rpt,"POSANSR=" 	    & status[POSANSR]);
		fil_putline(_fe_rpt,"POSPIN=" 	    & status[POSPIN]);
		fil_putline(_fe_rpt,"HUPB4BRIDGE="  & status[HUPB4BRIDGE]);
		fil_putline(_fe_rpt,"SHORTREC="     & status[SHORTREC]);
		fil_putline(_fe_rpt,"FULLREC=" 	    & status[FULLREC]);
		fil_putline(_fe_rpt,"EMPTYKUE="     & status[EMPTYKUE]);
		fil_putline(_fe_rpt,"POSOFFHOOK="   & status[POSOFFHOOK]);
		fil_putline(_fe_rpt,"SUCCESS="      & status[SUCCESS]);
		fil_putline(_fe_rpt,"NOREC="        & status[NOREC]);
		fil_putline(_fe_rpt,"TOPREJECT="    & status[TOPREJECT]);
		fil_putline(_fe_rpt,"TOHTIME="      & status[TOHTIME]);
		fil_putline(_fe_rpt,"CRA_SIDEID="   & procread("side_id",getpid()));
		fil_putline(_fe_rpt,"CRB_SIDEID="   & procread("side_id",getpid()));
		fil_putline(_fe_rpt,"TERMSTAT="     & procread("termstat",getpid()));
		fil_close(_fe_rpt);
		if(fil_info(PROC & rjust(getpid(),0,2) & "\final_report",1) > 0)
			_fe_rpt = -1;
			shell_wait(FSH_LOGTERM & " " & getpid() & " " & "final_report","-");
		
		else
			voslog("ERROR! - No final report generated.");
		endif
	
	endif 

	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	if(rec_pid <> 0)
		kill(rec_pid); 
	endif
	notify("inbound");

	clrsig(1,line);
	sc_sigctl("c"); # clear any events, turn off event handling suspension
	voslog("answer.vs pid " & getpid() & " exit-fsh_exit");
	restart;	

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
	
	voslog("enter-onsignal task # " & getpid());
	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);

	glb_set(getpid(),"HUP");
	sc_sigctl("c");

	switch(dnis)
	case DNIS_A:
		voslog("exit-onsignal task # " & getpid());
		fsh_exit(5,0,0,TRUE);			
	case DNIS_B:
		notify("inbound");
		DTI_clrsig(dboard,line,3);
		voslog("answer.vs exit-onsignal task # " & getpid());			
		restart;
	case DNIS_C:
		if(procexst("ce_pid",getpid()) and glb_get(procread("ce_pid",getpid())) strneq "HUP")
			sc_hangup(procread("ce_line",getpid()));
		endif
		voslog("answer.vs exit-onsignal task # " & getpid());
		cfibexit(procread("termstat",getpid()));
	default:
		notify("inbound");
		DTI_clrsig(dboard,line,3);
		voslog("answer.vs exit-onsignal task # " & getpid());
		restart;
	endswitch
end

func procexists(_fpr_fil,_fpr_pid)
        dec

        enddec
	voslog("entret-procexists task # " & getpid());
        if(fil_info(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,1) > 0)
                return(TRUE);
        else
          return(FALSE);
        endif

endfunc

