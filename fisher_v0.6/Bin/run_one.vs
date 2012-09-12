
dec
	include "fisher_core.inc"
	include "fisher_common.inc"
	include "fisher_perl.inc"
	include "fisher_prompts.inc"
	include "cfib_perl.inc"
	var number : 17;
	var calling : 22;	
	var acc_start : 8;
	var pin_verified : 1;
	var call_id : 10;
	var dbpin : 7;
	var lang : 3;
	var proj_id : 1;
	var lcheck : 8;

enddec

program

	
	lang = arg(1);
	proj_id = arg(2);

	breakpt[1] = "init";
	breakpt[2] = 1;
	msg_settaskname("run_oneT" & getpid());
      	msg_flush();
	
	## initialize status tables and milestone table ##
	for(ctr = 1;ctr <= 10;++ctr)
		fisher_call_status[ctr] = "X";
	endfor
	for(ctr = 1;ctr <=23;++ctr)
		status[ctr] = "X";
	endfor
	for(ctr = 1;ctr <= 9;++ctr)
		mileston[ctr] = "X";
	endfor
	breakpt[2] = 2;
	## call session can now begin ##
	fisher_call_status[FISHER_TERM_STAT] = "normal_exit";	
	tmr_start();	
	start_time = date(1) & "_" & time();
	log_times[LOG_START] = start_time;	

	mileston[M1] = tmr_secs();
	dboard = 1;

	# which line should I use?

	glb_set(getpid(),"WAIT");
	line = get_free_line();
	if(line < 12 or line > 24)
		voslog("run_one pid:" & getpid() & " : Critical Error: Failed to get line: invalid lineid: " & line);
		fisher_call_status[FISHER_TERM_STAT] = "nolines_exit";
		fsh_exit(5,breakpt[1],breakpt[2],FALSE);
	endif

	if(rectest(line,getpid()) <> 1)
		voslog("run_one pid:" & getpid() & " : Critical Error: rectest failed - canceling call");
		fisher_call_status[FISHER_TERM_STAT] = "recfail_exit";
		fsh_exit(5,breakpt[1],breakpt[2],FALSE);
	endif

	procwrit("line",line);
	procwrit("proj_id",proj_id);
	breakpt[2] = 3;

	sc_clrdigits(line);
	sc_toneint(line,0);
	fisher_call_status[FISHER_GETCALLEE_RSLT] = "no1avail";
	calling = get_callee(getpid());

	gettod();
	todsumm = procread("topic_summ.txt",getpid());
	topic = procread("topic.txt",getpid());

	mileston[M2] = tmr_secs();	
	pin_locked = 0;
	reca_pid = 0;
	recb_pid = 0;

	toh_start = 0;
	toh_end = 0;
	dbpin = substr(calling,1,strpos(calling,"|") - 1);
	number = substr(calling,length(dbpin) + 2);

	if(dbpin streq "XXXX" or dbpin streq "XXXXX")
		# no more callees available
		status[EMPTYKUE] = "yes";
		fisher_call_status[FISHER_TERM_STAT] = "noce_exit";
		fsh_exit(120,breakpt[1],breakpt[2],FALSE);
	else
		status[EMPTYKUE] = "no";
		pin_locked = 1;
		fisher_call_status[FISHER_GETCALLEE_RSLT] = "gotcalle";
	
	endif
	breakpt[2] = 4;

	voslog("run_one CALLING: " & calling & " PIN: " & dbpin & " Number: " & number);
  	procwrit("side_id",newside(PROJ_MX3,number,line,getpid()));
	fsplog(procread("side_id",getpid()),number,"io_phnum");
	fsplog(procread("side_id",getpid()),procread("subj_id",getpid()),"subj_id");
	fsplog(procread("side_id",getpid()),procread("phone_id",getpid()),"phone_id");
  	if(procread("side_id",getpid()) < 0)
		sc_play(line,pr_look(DBERR,lang), PBMODE);
  		procwrit("termstat","NEWSIDEERR");
		voslog("exit-fshib task # " & getpid());
		fsh_exit(5,breakpt[1],breakpt[2],FALSE);  
		
  	endif	
	
	vid_cur_pos(10,44);
	vid_set_attr(10,4);
	vid_print("Last OBC: " & number & " L" & line);
	vid_set_attr(7,0);

	ret = fisher_call(line,number);
	mileston[M3] = tmr_secs();
	toh_start = tmr_secs();	
	if(ret eq 1)
		status[HUPB4BRIDGE] = "yes";
		status[POSOFFHOOK] = "yes";
		

		sc_play(line,pr_look(HELLO_OB,lang),PBMODE);
		sc_play(line,namelook(dbpin),PBMODE);
		sc_play(line,pr_look(TOPICDAY,lang),PBMODE);
		sc_play(line,tpc_look(todsumm,lang),PBMODE);


		status[TOPREJECT] = "no";
		sc_clrdigits(line);
		breakpt[2] = 5;	
		for(ctr = 0;ctr <=2;++ctr)
			switch(cr_query(line,pr_look(ACCEPT_OB,lang),"123456789#*"))
			case 1:
				sc_clrdigits(line);
				fisher_call_status[FISHER_POSANSR_RSLT] = "ok";
				status[POSANSR] = "yes";
				status[TOPREJECT] = "no";
				break;
			case 2:
				sc_clrdigits(line);
				ctr = 0;
				sc_play(line,pr_look(URONHOLD,lang),PBMODE);
				fisher_call_status[FISHER_POSANSR_RSLT] = "wait";
				status[POSANSR] = "no";
				status[TOPREJECT] = "no";
				acc_start = tmr_secs();
				scb_route(FSH_MOH, SCB_VOX,dboard*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
				for(;;)
					if(tmr_secs() - acc_start > 30)
						break;
					endif
					sleep(1);
				endfor
				scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
			case 9:
				sc_clrdigits(line);
				fisher_call_status[FISHER_POSANSR_RSLT] = "reject";
				status[POSANSR] = "no";
				status[TOPREJECT] = "yes";
				break;
			case "":
				fisher_call_status[FISHER_POSANSR_RSLT] = "timeout";
				status[POSANSR] = "no";
			default:
				sc_clrdigits(line);
				sc_play(line,pr_look(INVALID,lang),PBMODE);
				status[POSANSR] = "no";
			endswitch
		endfor
		mileston[M4] = tmr_secs();
		breakpt[2] = 6;
		if(status[POSANSR] streq "no")
			fisher_call_status[FISHER_TERM_STAT] = "noposansr_exit";
			fsh_exit(5,breakpt[1],breakpt[2],FALSE);
		endif

		sc_play(line,pr_look(THANKYOU,lang),PBMODE);

	
		#validate pin
		pin_verified = 0;
		sc_play(line,pr_look(ENTERPIN,lang),PBMODE);
		for(ctr = 0;ctr < 6;++ctr)
			if(getpin() eq TRUE and procread("pin",getpid()) streq dbpin)
				pin = procread("pin",getpid());
				pin_verified = 1;
				status[POSPIN] = "yes";
				break;
			else
				sc_clrdigits(line);
				sc_play(line,pr_look(INVALID,lang),PBMODE);
				++ctr;
				status[POSPIN] = "no";
			endif
			
			if(ctr < 5)
				sc_play(line,pr_look(ENTERPIN2,lang),PBMODE);
			else
				break;
			endif
		endfor
		if(pin_verified <> TRUE)
			fsh_exit(5,breakpt[1],breakpt[2],FALSE);
		endif
		sc_play(line,pr_look(THANKYOU,lang),PBMODE);

		myphntype = cr_query(line,pr_look(PHNTYPE,lang),"123");
		procwrit("phntype",myphntype);	
      		fsplog(procread("side_id",getpid()),procread("phntype",getpid()),"phonetype");			

		myphnset = cr_query(line,pr_look(PHNSET,lang),"1234");
		procwrit("phnset",myphnset);	
      		fsplog(procread("side_id",getpid()),procread("phnset",getpid()),"phoneset");

		procwrit("namerec",recname(line,pin));
		fsplog(procread("side_id",getpid()),procread("namerec",getpid()),"namerec");

		sc_play(line,pr_look(HOLD,lang),PBMODE);
		
		log_times[LOG_ONHOLD] = date(1) & "_" & time();	
		notify("onhold");
	

		scb_route(FSH_MOH, SCB_VOX,dboard*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
		fisher_call_status[FISHER_ATT_BRDG] = "no_brdg";
		procwrit("ohdur",0);	
		oh_start = tmr_secs();
		for(;;)
			ret = msg_get(2);

			if(length(ret) <> 0) 
				mypair = substr(ret,1,strpos(ret,"X") - 1);	
				mypair_line = strend(ret,length(ret) - (length(mypair) + 1));
				voslog(ret & " " & mypair & " " & mypair_line);
				break;
			endif
			
			if(tmr_secs() - oh_start > 70)
				procwrit("ohdur",71);	
				scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
				
				for(ctr = 0;ctr < 5;++ctr)
					sc_play(line,pr_look(HOLD2,lang),PBMODE);
					#switch(getdtmf(line,pr_look(HOLDEXIT,lang),PBMODE))
					switch(cr_query(line,pr_look(HOLDEXIT,lang),"1234567890#*"))
					case 1:
						sc_clrdigits(line);
						sc_play(line,pr_look(THANKYOU,lang),PBMODE);
						oh_start = tmr_secs();	
						break;
					case 2:
						sc_clrdigits(line);
						sc_play(line,pr_look(THANKYOU,lang),PBMODE);
						oh_start = tmr_secs();	
						fsh_exit(3,breakpt[1],breakpt[2],FALSE);
					default:
						oh_start = tmr_secs();	
						sc_clrdigits(line);
						if(ctr <= 4)
							sc_play(line,pr_look(INVALID,lang),PBMODE);
							sc_play(line,pr_look(HOLDEXIT,lang),PBMODE);
						else
							fsh_exit(3,breakpt[1],breakpt[2],FALSE);
						endif
					endswitch
				endfor
				scb_route(FSH_MOH, SCB_VOX,dboard*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
			endif
		endfor
		procwrit("ohdur",0);	
		voslog(getpid() & " is paired with " & mypair);
		mileston[M5] = tmr_secs();
		breakpt[2] = 7;
		scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		fisher_call_status[FISHER_ATT_BRDG] = "bridged";
		mypair_pin     = procread("pin",     mypair);
		mypair_number  = procread("number",  mypair);
		mypair_phntype = procread("phntype", mypair);
		mypair_phnset  = procread("phnset",  mypair);
		sc_toneint(line,0); ## turn off barge-in

		sc_play(line,pr_look(WELCOME,lang),PBMODE);
		sc_play(line,pr_look(TOPICDAY,lang),PBMODE);
		sc_play(line,tpc_look(topic,lang),PBMODE);
		sc_play(line,pr_look(FSRECNOW,lang),PBMODE);
		sc_play(line,pr_look(FSINTRO,lang),PBMODE);
		sc_play(line,TONE,PBMODE);	
		glb_set(getpid(),"RECOK");
		for(;;)
			switch(glb_get(mypair))
			case "RECOK":
				break;
			case "HUP":
				fisher_call_status[FISHER_TERM_STAT] = "pairhup_exit";	
				fsh_exit(15,breakpt[1],breakpt[2],FALSE);
			endswitch
			sleep(1);
		endfor

		status[HUPB4BRIDGE] = "no";
		toh_end = tmr_secs();

		sc_toneint(line,0); ## turn off barge-in
		sc_sigctl("(");
		if(getpid() > mypair)
			call_id = logbrdg(PROJ_MX3,
					  procread("subj_id",getpid()),
					  procread("subj_id",mypair),
					  procread("side_id",getpid()),	
			  		  procread("side_id",mypair),
			  		  getpid());
			procwrit("cra_sideid",procread("side_id",getpid()));
			procsend("cra_sideid",procread("side_id",getpid()),mypair);

			procwrit("crb_sideid",procread("side_id",mypair));
			procsend("crb_sideid",procread("side_id",mypair),mypair);

			procwrit("call_id",call_id);
			procsend("call_id",call_id,mypair);

			procwrit("cra_subjid",procread("subj_id",getpid()));
			procsend("cra_subjid",procread("subj_id",getpid()),mypair);

			procwrit("crb_subjid",procread("subj_id",mypair));
			procsend("crb_subjid",procread("subj_id",mypair),mypair);

			voslog(getpid() & " is acting as master");

			scb_route(FSH_CLOCK, SCB_VOX, line       , SCB_VOX, SCB_HALF_DUPLEX); ## clock recording
			scb_route(FSH_CLOCK, SCB_VOX, mypair_line, SCB_VOX, SCB_HALF_DUPLEX); ## clock recording

			sema = line;
			semb = mypair_line;
			semc = sema + 24;
			semd = semb + 24;
			sem_set(sema);
			sem_set(semb);

			fnam_base = FSH_RECORDINGS & date(1) & "_" & time() & "_" & call_id; 
			fnama = fnam_base & "_A.ul";
			procwrit("fnama",fnama);
			procsend("fnama",fnama,mypair);

			fnamb = fnam_base & "_B.ul";
			procwrit("fnamb",fnamb);
			procsend("fnamb",fnamb,mypair);

			cname = gen_commname("A");
			# spawn recorder
			reca_pid = spawn("recorder",line,       sema,semc,fnama,FSH_RECLEN,getpid(),"A");
			recb_pid = spawn("recorder",mypair_line,semb,semd,fnamb,FSH_RECLEN,getpid(),"B");
			
			semblock(semc);
			semblock(semd);
			sem_clrall();

			scb_route(dboard*DTI_OFFSET + line, SCB_DTI, 
                                  dboard*DTI_OFFSET + mypair_line, SCB_DTI, 
                                  SCB_FULL_DUPLEX);
		else
			voslog(mypair & " is acting as master");
			cname = gen_commname("B");
		endif
		
		status[RECORDING] = 1;
		
		voslog("spawn ret: " & ret);
		conn_start = tmr_secs();
		lcheck = tmr_secs();
		## route for subject recording
		scb_route(dboard*DTI_OFFSET + line,        SCB_DTI, line       , SCB_VOX, SCB_HALF_DUPLEX); 
		## route for subject recording
		scb_route(dboard*DTI_OFFSET + mypair_line, SCB_DTI, mypair_line, SCB_VOX, SCB_HALF_DUPLEX); 
		sc_sigctl("c");
		sc_sigctl("(");
		for(;;)
			if(tmr_secs() - conn_start > FSH_RECLEN + 5)
				sc_sigctl("c");
				break;
			endif
			sc_sigctl("(");
			if(tmr_secs() > lcheck + 5)
				lcheck = tmr_secs();
				status[RUNTIME]  = tmr_secs();
				status[FILESIZA] = fil_info(fnama,1);		
				status[FILESIZB] = fil_info(fnamb,1);	
				procwrit("filesiza",status[FILESIZA]);
				procwrit("filesizb",status[FILESIZB]);
			endif
			sc_sigctl(")");
		endfor
		stoprec(line);
		stoprec(mypair_line);

		scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_play(line,pr_look(RECEND,lang),PBMODE);
		if(getpid() > mypair)						
			scb_route(dboard*DTI_OFFSET + line, SCB_DTI, 
                                  dboard*DTI_OFFSET + mypair_line, SCB_DTI, 
                                  SCB_FULL_DUPLEX);
		endif		
		
		b_end = tmr_secs();
		for(;;)
			if(tmr_secs() - b_end > 13)
				break;
			endif 
		endfor

		sc_sigctl("c");

		scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_clrdigits(line);
		sc_play(line,pr_look(TIMESUP,lang),PBMODE);
		sc_play(line,pr_look(PARTTHANK,lang),PBMODE);
		sc_play(line,pr_look(LEAVECOMM,lang),PBMODE);
		mileston[M6] = tmr_secs();
		breakpt[2] = 8;
		sc_getdigits(line,1,60,0);
		if(substr(sc_digits(line),1,1) streq "1")
			sc_record(line, cname, 45, 10, 1792, 2);
		endif
		sc_play(line,pr_look(THANKYOU,lang),PBMODE);
		sc_play(line,pr_look(GOODBYE,lang),PBMODE);
	# stop recording

	endif

	mileston[M7] = tmr_secs();
	breakpt[2] = 9;
	fsh_exit(5,breakpt[1],breakpt[2],FALSE);
	
endprogram

func fsh_exit(_fe_rsdelay,_fe_bpt,_fe_bpref,_fe_onsig)
	dec
		var _fe_rpt: 4;
		var _fe_sutdelta: 8;
	enddec

	sc_sigctl("("); #allow exit to finish 
	stoprec(line);	
	stoprec(mypair_line);

	glb_set(getpid(),"HUP");
	if(toh_end eq 0 and toh_start > 0)
		toh_end = tmr_secs();
	endif
	status[TOHTIME] = toh_end - toh_start;

	if(pin_locked eq 1)
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

		_fe_rpt = fil_open(PROC & rjust(getpid(),0,2) & "\final_report","trwc");
		voslog("EXITING: " & pin & " " & number);	
		voslog("FINALRPT: " & PROC & rjust(getpid(),0,2) & "\final_report : " & " " & _fe_rpt);	

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
		fil_putline(_fe_rpt,"NUMBER="       & number);
		fil_putline(_fe_rpt,"PAIR="         & mypair_pin);		
		fil_putline(_fe_rpt,"PAIRNUMBER="   & mypair_number);		
		fil_putline(_fe_rpt,"MYPHNSET="     & myphnset);
		fil_putline(_fe_rpt,"PAIRPHNSET="   & mypair_phnset);
		fil_putline(_fe_rpt,"MYPHNTYPE="    & myphntype);
		fil_putline(_fe_rpt,"PAIRPHNTYPE="  & mypair_phntype);
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
		fil_putline(_fe_rpt,"CRA_SIDEID="   & procread("cra_sideid",getpid()));
		fil_putline(_fe_rpt,"CRB_SIDEID="   & procread("crb_sideid",getpid()));
		fil_putline(_fe_rpt,"TERMSTAT="     & procread("termstat",getpid()));
		fil_close(_fe_rpt);
		_fe_rpt = -1;
		voslog(    FSH_LOGTERM & " " & getpid() & " " & "final_report");
		shell_wait(FSH_LOGTERM & " " & getpid() & " " & "final_report","-");
		shell_wait(MX3_UDCMADE,"-");
		clrproc(getpid());
	else
		delproc(getpid());
	endif 

	if(line > 1)
		sc_abort(line);
		do
			sleep(1);
		until (sc_stat(line) eq 0);

		DTI_clrtrans(1,line);
		clrsig(1,line);
	endif

	sleep(200);
	release_line(line);
	sc_sigctl("c"); # clear any events, turn off event handling suspension

	restart;

endfunc


func get_free_line()

	dec
		var _gfl_line : 2;
		var _gfl_ctr  : 2;
		var _gfl_mrtn : 2;
		var _gfl_test : 2;
	enddec
	breakpt[1] = "get_free_line";
	_gfl_line = -1;

	while(glb_get(1) strneq "LINEMGR_UP")
		voslog("run_one PID " & getpid() & " waiting for linemgr to reset " & glb_get(1) & " <> LINEMGR_UP!");
		sleep(1);
	endwhile

	_gfl_mrtn = msg_put("linemgr","request");
	if(_gfl_mrtn eq 0)
		for(;;)
			_gfl_test = msg_get(2);
			if(msg_pid() eq 1 and _gfl_test >= 13 and _gfl_test <= 24 )
				_gfl_line = _gfl_test;
				voslog("run_one got valid response from linemgr - continuing");
				break;
			else	
				voslog(" run_one recvd spurious message: " & _gfl_test & " from pid " & msg_pid());
				sleep(1);	
			endif
		endfor
	else
		voslog("run_one msg_put request to linemgr failed with error code: " & _gfl_mrtn);
	endif

 	return(_gfl_line);

endfunc

func release_line(_release_line_arg1)

	dec
		var _rl_ret : 2;
	enddec

	vid_cur_pos(3,6);
	vid_set_attr(10,1);

	breakpt[1] = "release_line";
	msg_put("linemgr","release");
	_rl_ret = msg_get(60);
		
	switch(_rl_ret)
	case 1:
		vid_print("CLOK");
	case 2:
		vid_print("LRER");
	default:
		vid_print("NRER");
	endswitch
	
	DTI_clrtrans(1, _release_line_arg1);
	clrsig(1, _release_line_arg1);
	return(_rl_ret);

endfunc

func fisher_call(_fisher_call_arg1,_fisher_call_arg2)
	dec
		var _line : 2;
		var _vline : 2;
		var _number : 17;
		var _board : 1;
		var _connected : 1;
		var _ctr : 1;
	enddec
	breakpt[1] = "fisher_call";
	_board = 1;
	_line = _fisher_call_arg1;
	_vline = _fisher_call_arg1;
	_number = _fisher_call_arg2;
	_connected = 0;

	scb_route(_board*DTI_OFFSET + _line, SCB_DTI, _vline, SCB_VOX, SCB_FULL_DUPLEX);

	for(_ctr = 0;_ctr < 6;++_ctr)
		clrsig(_board,   _line);
		
    		DTI_clrtrans(_board, _line);
    		DTI_watch(_board,    _line, "w");
       		DTI_setsig(_board,   _line, 3); 
		fisher_call_status[FISHER_CALL_WAITTRANS] = DTI_waittrans(_board,_line,"w",10);
		fisher_call_status[FISHER_CALL_GETSIG]    = DTI_getsig(_board,_line);
		if(fisher_call_status[FISHER_CALL_WAITTRANS] eq 6)
			voslog("GETSIG: " & fisher_call_status[FISHER_CALL_GETSIG]);
			voslog("Calling phone number " & _number & " on line " & _vline);
			sc_call(_vline,_number);
			DTI_clrtrans(_board, _line);
			DTI_watch(_board,_line,"Aa");
			DTI_use(_board,_line,"a");
			fisher_call_status[FISHER_CALL_GETCAR]  = sc_getcar(_vline);
			fisher_call_status[FISHER_CALL_CARDATA] = sc_cardata(_vline,6);
			fisher_call_status[FISHER_CALL_PAMD]    = sc_cardata(_vline,7);	
			switch(fisher_call_status[FISHER_CALL_GETCAR])
			case 7:
				_connected = 0;
				voslog("Failed to connect: BUSY Signal");
			case 8:
				_connected = 0;
				voslog("Failed to connect: No Answer");
			case 9:
				_connected = 0;
				voslog("Failed to connect: No Ring");
			case 10:
				voslog("Full connect - PAMD Code: " & sc_cardata(_line,7));
				_connected = 1;
				switch(sc_cardata(_line,7))
				case 1:
					voslog("CARDATA CONNTYPE: Cadence Break");
				case 2:
					voslog("CARDATA CONNTYPE: Loop On/Abit On");
				case 3:
					voslog("CARDATA CONNTYPE: Positive Voice Detection");
				case 4:
					voslog("CARDATA CONNTYPE: Positive Answering Machine Detection");
				default:
					voslog("CARDATA CONNTYPE: " & sc_cardata(_line,7) & " is not a valid return value.");
				endswitch
			case 11:
				_connected = 0;
				voslog("Failed to connect: Operator Intercept");
			case 17:
				_connected = 0;
				voslog("Failed to connect: No Dialtone");
			case 18:
				_connected = 0;
				voslog("Failed to connect: Fax tone received");
			default:
				_connected = 0;
				voslog("Failed to connect: XXX");
			endswitch
			break;
		else
			voslog("WAITTRANS " & fisher_call_status[FISHER_CALL_WAITTRANS]);
			_connected = 0;
 			DTI_clrtrans(_board,_line);
			clrsig(_board,_line);
			sleep(1);
		endif
	endfor
	if(_connected <> 1)
		voslog("Unable to connect to " & _number & " using line " & _line);
	endif

	return(_connected);

endfunc

func gen_commname(_gc_arg1)
	dec
		var _gc_fname : 80; 
	enddec
	breakpt[1] = "gen_commname";
	if(_gc_arg1 streq "A")
		_gc_fname = FSH_COMMENTS & date(1) & "_" & time() & "_" & pin & "_" & mypair_pin & "_" & _gc_arg1 & ".ul";
	else
		_gc_fname = FSH_COMMENTS & date(1) & "_" & time() & "_" & mypair_pin & "_" & pin & "_" & _gc_arg1 & ".ul";
	endif
	voslog("for comments using " & _gc_fname);
	return(_gc_fname);
endfunc
func get_callee(_gc_proc)
	dec
		var _gc_ret : 100;
		var _gc_fn : 100;
	enddec
	breakpt[1] = "get_callee";
	_gc_fn = PROC & rjust(_gc_proc,0,2) & "\getcallee_resp.txt";

	if(fil_info(_gc_fn,1) > 0)
		fil_delete(_gc_fn);
	endif

	shell_wait(FSH_GETCALLEE & " " & _gc_proc,"-");
	_gc_ret = procread("getcallee_resp.txt",getpid());

	if(_gc_ret eq -1)
		fisher_call_status[FISHER_GETCALLEE_RSLT] = "orclerr";
		_gc_ret = "XXXX|XXXXXXXXXXX";
	endif
	fil_delete(_gc_fn);
	return(_gc_ret);
endfunc
func get_pinfname(_gp_arg1)
	dec 
		var _gp_ret : 80;
	enddec
	breakpt[1] = "get_pinfname";
	shell_wait(FSH_GETPINFNAME & " " & rjust(getpid(),0,2) & " " & _gp_arg1,"-");
	_gp_ret = procread("getpinfname_resp.txt",getpid());
	fil_delete(PROC & rjust(getpid(),0,2) & "\getpinfname_resp.txt");
	return(_gp_ret);
endfunc
onsignal
	fisher_call_status[FISHER_TERM_STAT] = "onsig_exit";
	voslog("onsignal");
	clrsig(1,line);
	mileston[M7] = tmr_secs();
	fsh_exit(5,breakpt[1],breakpt[2],TRUE);
end

