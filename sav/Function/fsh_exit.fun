
func fsh_exit(_fe_rsdelay,_fe_bpt,_fe_bpref,_fe_onsig,_fe_mode)
	dec
		var _fe_rpt: 4;
		var _fe_sutdelta: 8;
		var _fe_pid: 4;
	enddec

	_fe_pid = getpid();

	sc_sigctl("("); #allow exit to finish 

	voslog("fsh_exit " & _fe_pid    & " " &
			     _fe_rsdelay & " " &
			     _fe_bpt     & " " &
			     _fe_bpref   & " " & 
			     _fe_onsig   & " " &
			     _fe_mode);

	if(line > 0)
		stoprec(line);	
	endif
	if(mypair_line > 0)
		stoprec(mypair_line);
	endif

	glb_set(_fe_pid,"HUP");
	if(toh_end eq 0 and toh_start > 0)
		toh_end = tmr_secs();
	endif
	status[TOHTIME] = toh_end - toh_start;

	if(pin_locked eq 1)
		if(line > 0)
			if(DTI_getsig(1,line) streq "1111")
				sc_play(line,pr_look(GOODBYE,lang),PBMODE);
			endif
		endif

		status[FILESIZA] = procread("filesiza",_fe_pid);
		status[FILESIZB] = procread("filesizb",_fe_pid);
		
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

		_fe_rpt = fil_open(PROC & rjust(_fe_pid,0,2) & "\final_report","trwc");
	
		fil_putline(_fe_rpt,"CALL_ID="      & procread("call_id",_fe_pid));	
		fil_putline(_fe_rpt,"FILA="         & procread("fnama",_fe_pid));
		fil_putline(_fe_rpt,"FILB="         & procread("fnamb",_fe_pid));
		fil_putline(_fe_rpt,"FILESIZA="     & procread("filesiza",_fe_pid));
		fil_putline(_fe_rpt,"FILESIZB="     & procread("filesizb",_fe_pid));
		fil_putline(_fe_rpt,"SUBJ_ID="      & procread("subj_id",_fe_pid));
		fil_putline(_fe_rpt,"CE_SUBJ_ID="   & procread("crb_subjid",_fe_pid));
		fil_putline(_fe_rpt,"CRA_SUBJID="   & procread("cra_subjid",_fe_pid));
		fil_putline(_fe_rpt,"CRB_SUBJID="   & procread("crb_subjid",_fe_pid));
		fil_putline(_fe_rpt,"TIMESTAMP="    & date(1) & "_" & time());		
		fil_putline(_fe_rpt,"PIN="          & pin);
		fil_putline(_fe_rpt,"NUMBER="       & number);
		fil_putline(_fe_rpt,"PAIR="         & mypair_pin);		
		fil_putline(_fe_rpt,"PAIRNUMBER="   & mypair_number);

		fil_putline(_fe_rpt,"MYNOISEYN="    & mynoiseyn);
		fil_putline(_fe_rpt,"PAIRNOISEYN="  & mypair_noiseyn);
		fil_putline(_fe_rpt,"MYPHNSET="     & myphnset);
		fil_putline(_fe_rpt,"PAIRPHNSET="   & mypair_phnset);
		fil_putline(_fe_rpt,"MYPHNTYPE="    & myphntype);
		fil_putline(_fe_rpt,"PAIRPHNTYPE="  & mypair_phntype);		
		fil_putline(_fe_rpt,"TOPIC="        & topic);
		fil_putline(_fe_rpt,"TOPIC_ID="     & procread("topic_id",_fe_pid));
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
		fil_putline(_fe_rpt,"CRA_SIDEID="   & procread("cra_sideid",_fe_pid));
		fil_putline(_fe_rpt,"CRB_SIDEID="   & procread("crb_sideid",_fe_pid));
		fil_putline(_fe_rpt,"TERMSTAT="     & procread("termstat",_fe_pid));
		fil_close(_fe_rpt);
		_fe_rpt = -1;
		shell_wait(FSH_LOGTERM & " " & _fe_pid & " " & "final_report","-");
		shell_wait(MX3_UDCMADE,"-");
		clrproc(_fe_pid);
	else
		delproc(_fe_pid);
	endif 

	if(line > 0)

		sc_abort(line);
		do
			sleep(1);
		until (sc_stat(line) eq 0);

		DTI_clrtrans(1,line);
		clrsig(1,line);
	endif

	if(_fe_mode eq ANSRMODE)
		notify("inbound");
	else
		if(line > 0)
			rlseline(line);
		endif
	endif

	sc_sigctl("c"); # clear any events, turn off event handling suspension
	restart;	

endfunc




