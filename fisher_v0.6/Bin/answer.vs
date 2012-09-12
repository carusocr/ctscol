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
	var adinfo   : 25;
	var ani      : 20;
	var dnis     : 8;
 	var lang     : 3;
	var ans_pid  : 6;
	var rec_pid  : 4;
	var stat_rtn : 2;
	var dtmfpending   : 3;
	var tonedetect    : 1;
	var silencedetect : 1;
	var dtmfrecvct : 3;
        var sctr : 2;
	var tickstart : 10;
	var tickdelta : 10;
	var mintdelta : 10;

enddec

program	

	ans_pid = getpid();
	msg_settaskname("answerT" & ans_pid);	
      	msg_flush();	
	clrproc(ans_pid);
	line = arg(1);

	if(line < 1 or line > 48)
		voslog("Critical Error: Failed to get line: invalid lineid: " & line);
		restart;
	endif
	
	dboard = 1;
	glb_set(ans_pid,"WAIT");

	mintdelta = get_min_tdelta();

	procwrit("line",line);

	notify("inbound");

	scb_route(dboard*256 + line,SCB_DTI,line,SCB_VOX,SCB_FULL_DUPLEX);
	DTI_clrsig(dboard,line,3);
	DTI_clrtrans(dboard,line);
	sc_clrdigits(line);
	adinfo = "";

	dtmfrecvct = 0;
	tickdelta  = 0;

	DTI_watch(dboard,line,"Aa");
	DTI_use(dboard,line,"a");
	do
		DTI_wait(dboard,line);
	until(DTI_trans(dboard,line,"A"));

	DTI_wink(dboard,line);

	tickstart = ticks();

	while(tickdelta < mintdelta)
		tickdelta = ticks() - tickstart;
		if(modulo(tickdelta,5) eq 0 and sc_stat(line,4) > 16)
			break;
		endif
	endwhile

	DTI_setsig(dboard,line, 3);	
	sc_getdigits(line,sc_stat(line,4));
	adinfo = sc_digits(line);
	sc_clrdigits(line);

	glb_set(ans_pid,"WINK");
	sc_playtone(line,460,455,-10,-10,100);	


	voslog("tickdelta " & tickdelta);
	voslog("ADinfo for line " & line & ": " & adinfo);

	adinfo = strstrip(strstrip(adinfo,"*"),"#");

	ani = substr(adinfo,1,10);
 
	if(length(ani) < 1)
	        ani = "2155739458";
	endif 

	if(length(adinfo) < 14)
		dnis = DNIS_A;
	else
		dnis = substr(adinfo,11,4);
	endif

	glb_set(ans_pid,"DN" & substr(dnis,3,2));

	voslog("IBC:" & ani & " LINE:" & line);

	switch(dnis)
	case DNIS_A:
		lang = ENG;
		cfib(line,ani);
	case DNIS_B:
		lang = ENG;
		cfib(line,ani);
	case DNIS_C:
		lang = TON;
		cfib(line,ani);
	default:
		voslog("dtmf buffer: " & adinfo);
		set_min_tdelta(tickdelta);
		dnis = DNIS_A;
		ani = "2155739458";
		lang = ENG;
		cfib(line,ani);
	endswitch	
	
	sc_clrdigits(line);
	voslog("answer.vs pid " & getpid() & " Restarting");
	
	notify("inbound");
	DTI_clrsig(dboard, line, 3);
	glb_set(ans_pid,"RESTART");
	restart;

endprogram

func rejlist(_test_ani)
	dec
		var _isblacklisted: 1;
		var _fh : 8;
	enddec
	_isblacklisted = FALSE;
	_fh = fil_open(LDC_REJLIST, "rs");
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
		var _pid : 6;
	enddec

	_pid = getpid();

	voslog("enter-fsh_exit task # " & _pid);
	sc_sigctl("("); #allow exit to finish 
	stoprec(line);	
	stoprec(mypair_line);
	glb_set(_pid,"HUP");
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
		

		_fe_rpt = fil_open(PROC & rjust(_pid,0,2) & "\final_report","trwc");
		voslog("Using Filehandle " &_fe_rpt);
	
		fil_putline(_fe_rpt,"CALL_ID="      & procread("call_id",_pid));	
		fil_putline(_fe_rpt,"FILA="         & procread("fnama",_pid));
		fil_putline(_fe_rpt,"FILB="         & procread("fnamb",_pid));
		fil_putline(_fe_rpt,"FILESIZA="     & procread("filesiza",_pid));
		fil_putline(_fe_rpt,"FILESIZB="     & procread("filesizb",_pid));
		fil_putline(_fe_rpt,"SUBJ_ID="      & procread("cra_subjid",_pid));
		fil_putline(_fe_rpt,"CE_SUBJ_ID="   & procread("crb_subjid",_pid));
		fil_putline(_fe_rpt,"CRA_SUBJID="   & procread("cra_subjid",_pid));
		fil_putline(_fe_rpt,"CRB_SUBJID="   & procread("crb_subjid",_pid));
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
		fil_putline(_fe_rpt,"TOPIC_ID="     & procread("topic_id",_pid));
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
		fil_putline(_fe_rpt,"CRA_SIDEID="   & procread("side_id",_pid));
		fil_putline(_fe_rpt,"CRB_SIDEID="   & procread("side_id",_pid));
		fil_putline(_fe_rpt,"TERMSTAT="     & procread("termstat",_pid));
		fil_close(_fe_rpt);
		if(fil_info(PROC & rjust(getpid(),0,2) & "\final_report",1) > 0)
			_fe_rpt = -1;
			shell_wait(FSH_LOGTERM & " " & _pid & " " & "final_report","-");
		
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
	voslog("answer.vs pid " & _pid & " exit-fsh_exit");
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
	
	ans_pid = getpid();

	voslog("enter-onsignal task # " & ans_pid);
	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);

	glb_set(ans_pid,"HUP");
	sc_sigctl("c");

	switch(dnis)
	case DNIS_A:
		voslog("exit-onsignal task # " & ans_pid);
		fsh_exit(5,0,0,TRUE);			
	case DNIS_B:
		notify("inbound");
		DTI_clrsig(dboard,line,3);
		voslog("answer.vs exit-onsignal task # " & ans_pid);			
		restart;
	case DNIS_C:
		if(procexst("ce_pid",ans_pid) and glb_get(procread("ce_pid",ans_pid)) strneq "HUP")
			sc_hangup(procread("ce_line",ans_pid));
		endif
		voslog("answer.vs exit-onsignal task # " & ans_pid);
		cfibexit(procread("termstat",ans_pid));
	default:
		notify("inbound");
		DTI_clrsig(dboard,line,3);
		voslog("answer.vs exit-onsignal task # " & ans_pid);
		restart;
	endswitch
end

func get_min_tdelta()
     dec
	var rtn : 8; 
     enddec	
     
     rtn = procread("min_tdelta",99);	

     return(rtn);

endfunc

func set_min_tdelta(_cmtd)
     
     dec
	var _fh : 4;
	var _ncmv : 2; 
     enddec


     if(_ncmv > 60)     
     	 _ncmv = _cmtd - 1;
     else
	_ncmv = 80;
     endif
     _fh  = fil_open(PROC & "99\min_tdelta","twc");	
     fil_putline(_fh,_ncmv);
     fil_close(_fh);
     return(_ncmv);

endfunc     


func procexists(_fpr_fil,_fpr_pid)
        dec

        enddec

        if(fil_info(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,1) > 0)
                return(TRUE);
        else
          return(FALSE);
        endif

endfunc

