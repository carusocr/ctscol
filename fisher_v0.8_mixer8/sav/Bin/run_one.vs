
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
	ro_pid = getpid();
	voslog("run_one " & lang & " " & proj_id & " " & ro_pid);
	breakpt[1] = "init";
	breakpt[2] = 1;
	msg_settaskname("run_oneT" & ro_pid);
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
	

	# which line should I use?

	glb_set(ro_pid,"WAIT");
	line = get_free_line();
	if(line < MIN_OBLINE or line > MAX_OBLINE)
		voslog("run_one pid:" & ro_pid & " : Critical Error: Failed to get line: invalid lineid: " & line);
		fisher_call_status[FISHER_TERM_STAT] = "nolines_exit";
		fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
	endif

	voslog("using line " & line);

	if(rectest(line,ro_pid) <> 1)
		voslog("run_one pid:" & ro_pid & " : Critical Error: rectest failed - canceling call");
		fisher_call_status[FISHER_TERM_STAT] = "recfail_exit";
		fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
	endif

	procwrit("line",line);
	procwrit("proj_id",proj_id);
	breakpt[2] = 3;

	sc_clrdigits(line);
	sc_toneint(line,0);
	fisher_call_status[FISHER_GETCALLEE_RSLT] = "no1avail";
	calling = get_callee(ro_pid);

	gettod();
	todsumm = procread("topic_summ.txt",ro_pid);
	topic = procread("topic.txt",ro_pid);

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
		fsh_exit(120,breakpt[1],breakpt[2],FALSE,DIALMODE);
	else
		status[EMPTYKUE] = "no";
		pin_locked = 1;
		fisher_call_status[FISHER_GETCALLEE_RSLT] = "gotcalle";
	
	endif
	breakpt[2] = 4;

	voslog("run_one CALLING: " & calling & " PIN: " & dbpin & " Number: " & number);
  	procwrit("side_id",newside(PROJ_MX3,number,line,ro_pid));
	fsplog(procread("side_id",ro_pid),number,"io_phnum");
	fsplog(procread("side_id",ro_pid),procread("subj_id",ro_pid),"subj_id");
	fsplog(procread("side_id",ro_pid),procread("phone_id",ro_pid),"phone_id");
  	if(procread("side_id",ro_pid) < 0)
		sc_play(line,pr_look(DBERR,lang), PBMODE);
  		procwrit("termstat","NEWSIDEERR");
		voslog("exit-fshib task # " & ro_pid);
		fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);  
		
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
				scb_route(FSH_MOH, SCB_VOX,DTI_BOARD*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
				for(;;)
					if(tmr_secs() - acc_start > 30)
						break;
					endif
					sleep(1);
				endfor
				scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
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
			fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
		endif

		sc_play(line,pr_look(THANKYOU,lang),PBMODE);

		if(recaccpt(line,lang) <> FSH_RECACCEPT)
			procwrit("termstat","REJECTERR");
			voslog("exit-fshib task # " & ro_pid);  
			fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
		endif


		#validate pin
		pin_verified = 0;
		sc_play(line,pr_look(ENTERPIN,lang),PBMODE);
		for(ctr = 0;ctr < 6;++ctr)
			if(getpin() eq TRUE and procread("pin",ro_pid) streq dbpin)
				pin = procread("pin",ro_pid);
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
			fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
		endif
		sc_play(line,pr_look(THANKYOU,lang),PBMODE);


		mynoiseyn = cr_query(line,pr_look(NOISEYN,lang),"12");
		procwrit("noiseyn",mynoiseyn);
		fsplog(procread("side_id",ro_pid), procread("noiseyn",ro_pid), "with_noise");
		
		myphntype = cr_query(line,pr_look(PHNTYPE,lang),"123");
		procwrit("phntype",myphntype);	
      		fsplog(procread("side_id",ro_pid),procread("phntype",ro_pid),"phonetype");			

		myphnset = cr_query(line,pr_look(PHNSET,lang),"1234");
		procwrit("phnset",myphnset);	
      		fsplog(procread("side_id",ro_pid),procread("phnset",ro_pid),"phoneset");

		procwrit("namerec",recname(line,pin));
		fsplog(procread("side_id",ro_pid),procread("namerec",ro_pid),"namerec");

		sc_play(line,pr_look(HOLD,lang),PBMODE);
		
		log_times[LOG_ONHOLD] = date(1) & "_" & time();	
		notify("onhold");
	

		scb_route(FSH_MOH, SCB_VOX,DTI_BOARD*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
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
				scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
				
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
						fsh_exit(3,breakpt[1],breakpt[2],FALSE,DIALMODE);
					default:
						oh_start = tmr_secs();	
						sc_clrdigits(line);
						if(ctr <= 4)
							sc_play(line,pr_look(INVALID,lang),PBMODE);
							sc_play(line,pr_look(HOLDEXIT,lang),PBMODE);
						else
							fsh_exit(3,breakpt[1],breakpt[2],FALSE,DIALMODE);
						endif
					endswitch
				endfor
				scb_route(FSH_MOH, SCB_VOX,DTI_BOARD*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
			endif
		endfor
		procwrit("ohdur",0);	
		voslog(ro_pid & " is paired with " & mypair);
		mileston[M5] = tmr_secs();
		breakpt[2] = 7;
		scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		fisher_call_status[FISHER_ATT_BRDG] = "bridged";
		mypair_pin     = procread("pin",     mypair);
		mypair_number  = procread("number",  mypair);
		mypair_phntype = procread("phntype", mypair);
		mypair_phnset  = procread("phnset",  mypair);
		mypair_noiseyn = procread("noiseyn", mypair);
		
		sc_toneint(line,0); ## turn off barge-in

		sc_play(line,pr_look(WELCOME,lang),PBMODE);
		sc_play(line,pr_look(TOPICDAY,lang),PBMODE);
		sc_play(line,tpc_look(topic,lang),PBMODE);
		sc_play(line,pr_look(FSRECNOW,lang),PBMODE);
		sc_play(line,pr_look(FSINTRO,lang),PBMODE);
		sc_play(line,TONE,PBMODE);	
		glb_set(ro_pid,"RECOK");
		for(;;)
			switch(glb_get(mypair))
			case "RECOK":
				break;
			case "HUP":
				fisher_call_status[FISHER_TERM_STAT] = "pairhup_exit";	
				fsh_exit(15,breakpt[1],breakpt[2],FALSE,DIALMODE);
			endswitch
			sleep(1);
		endfor

		status[HUPB4BRIDGE] = "no";
		toh_end = tmr_secs();

		sc_toneint(line,0); ## turn off barge-in
		sc_sigctl("(");
		if(ro_pid > mypair)
			call_id = logbrdg(PROJ_MX3,
					  procread("subj_id",ro_pid),
					  procread("subj_id",mypair),
					  procread("side_id",ro_pid),	
			  		  procread("side_id",mypair),
			  		  ro_pid);
			procwrit("cra_sideid",procread("side_id",ro_pid));
			procsend("cra_sideid",procread("side_id",ro_pid),mypair);

			procwrit("crb_sideid",procread("side_id",mypair));
			procsend("crb_sideid",procread("side_id",mypair),mypair);

			procwrit("call_id",call_id);
			procsend("call_id",call_id,mypair);

			procwrit("cra_subjid",procread("subj_id",ro_pid));
			procsend("cra_subjid",procread("subj_id",ro_pid),mypair);

			procwrit("crb_subjid",procread("subj_id",mypair));
			procsend("crb_subjid",procread("subj_id",mypair),mypair);

			voslog(ro_pid & " is acting as master");

			scb_route(FSH_CLOCK, SCB_VOX, line       , SCB_VOX, SCB_HALF_DUPLEX); ## clock recording
			scb_route(FSH_CLOCK, SCB_VOX, mypair_line, SCB_VOX, SCB_HALF_DUPLEX); ## clock recording

			sema = line;
			semb = mypair_line;
			semc = sema + SEM_OFFSET;
			semd = semb + SEM_OFFSET;
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
			reca_pid = spawn("recorder",line,       sema,semc,fnama,FSH_RECLEN,ro_pid,"A");
			recb_pid = spawn("recorder",mypair_line,semb,semd,fnamb,FSH_RECLEN,ro_pid,"B");
			
			semblock(semc);
			semblock(semd);
			sem_clrall();

			scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, 
                                  DTI_BOARD*DTI_OFFSET + mypair_line, SCB_DTI, 
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
		scb_route(DTI_BOARD*DTI_OFFSET + line,        SCB_DTI, line       , SCB_VOX, SCB_HALF_DUPLEX); 
		## route for subject recording
		scb_route(DTI_BOARD*DTI_OFFSET + mypair_line, SCB_DTI, mypair_line, SCB_VOX, SCB_HALF_DUPLEX); 
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

		scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_play(line,pr_look(RECEND,lang),PBMODE);
		if(ro_pid > mypair)						
			scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, 
                                  DTI_BOARD*DTI_OFFSET + mypair_line, SCB_DTI, 
                                  SCB_FULL_DUPLEX);
		endif		
		
		b_end = tmr_secs();
		for(;;)
			if(tmr_secs() - b_end > 13)
				break;
			endif 
		endfor

		sc_sigctl("c");

		scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
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
	fsh_exit(5,breakpt[1],breakpt[2],FALSE,DIALMODE);
	
endprogram


func get_free_line()

	dec
		var _gfl_line : 2;
		var _gfl_mrtn : 2;
		var _gfl_test : 2;
	enddec

	breakpt[1] = "get_free_line";
	_gfl_line = -1;

	do
	until(glb_get(1) streq "LINEMGR_UP");

	# _gfl_mrtn = msg_put("linemgr","request");
	_gfl_mrtn = msg_put(1 , "request");
	if(_gfl_mrtn eq 0)
		_gfl_test = msg_get(2);	
		if(msg_pid() eq 1 and _gfl_test >= MIN_OBLINE and _gfl_test <= MAX_OBLINE )
			_gfl_line = _gfl_test;
		else
			voslog("Invalid response: " & _gfl_test);
		endif
		
	else
		voslog("run_one msg_put request to linemgr failed with error code: " & _gfl_mrtn);
	endif

 	return(_gfl_line);

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

	sem_set(SEM_CALLING);
	
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
		
		if(fisher_call_status[FISHER_CALL_WAITTRANS] eq 6)
		
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
		endif
	endfor

	sem_clear(SEM_CALLING);

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
	
	sem_set(SEM_GETCALLEE);
	shell_wait(FSH_GETCALLEE & " " & _gc_proc,"-");
	sem_clear(SEM_GETCALLEE);

	_gc_ret = procread("getcallee_resp.txt",ro_pid);

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
	shell_wait(FSH_GETPINFNAME & " " & rjust(ro_pid,0,2) & " " & _gp_arg1,"-");
	_gp_ret = procread("getpinfname_resp.txt",ro_pid);
	fil_delete(PROC & rjust(ro_pid,0,2) & "\getpinfname_resp.txt");
	return(_gp_ret);
endfunc
onsignal
	sem_clrall();
	fisher_call_status[FISHER_TERM_STAT] = "onsig_exit";
	voslog("onsignal");
	clrsig(1,line);
	mileston[M7] = tmr_secs();
	fsh_exit(5,breakpt[1],breakpt[2],TRUE,DIALMODE);
end

