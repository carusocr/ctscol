
func fshib(line,number,proj_id)
	dec
		var _fi_ctr : 2;
		var call_id : 10;
		var _fi_pinOK : 1;
		var lcheck : 8;
	enddec

	procwrit("line",line);
	notify("fshib");
	procwrit("number",number);
	procwrit("proj_id",proj_id);
	dboard = 1;	
	sc_clrdigits(line);	

	# get side_id
  	procwrit("side_id",newside(procread("proj_id",ro_pid),number,line,ro_pid));
  	if(procread("side_id",ro_pid) < 0)

		sc_play(line,pr_look(DBERR,lang),PBMODE);

  		procwrit("termstat","NEWSIDEERR");
		voslog("exit-fshib task # " & ro_pid);  
		fsh_exit(0,0,0,FALSE,ANSRMODE);
  	endif	
	gettod();
	todsumm = procread("topic_summ.txt",ro_pid);
	topic = procread("topic.txt",ro_pid);

	toh_start = 0;
	toh_end = 0;
	tmr_start();
	start_time = date(1) & "_" & time();
	for(ctr = 1;ctr <= 23;++ctr)
		status[ctr] = "X";
	endfor
	
	sc_toneint(line,0);

	sc_play(line,pr_look(HELLO_IB,lang),PBMODE);	
	sc_toneint(line,1);

	sc_play(line,pr_look(TOPICDAY,lang),PBMODE);
	sc_play(line,tpc_look(todsumm,lang),PBMODE);

	sc_clrdigits(line);
	sc_getdigits(line, 17);
	voslog("dtmf buffer: " & sc_digits(line));
	sc_clrdigits(line);

	if(recaccpt(line,lang) <> FSH_RECACCEPT)
  		procwrit("termstat","REJECTERR");
		voslog("exit-fshib task # " & ro_pid);  
		fsh_exit(0,0,0,FALSE,ANSRMODE);
	endif

	sc_clrdigits(line);
	sc_toneint(line,1);
	sc_play(line,pr_look(ENTERPIN,lang),PBMODE);

	status[TOPREJECT] = "yes";
	status[POSANSR] = "yes";
	reca_pid = 0;
	recb_pid = 0;
	_fi_ctr = 0;
	_fi_pinOK = -1;

	sc_toneint(line,0);
	for(_fi_ctr = 0;_fi_ctr <= 4;++_fi_ctr)

		if(getpin() eq TRUE)
			sc_clrdigits(line);
			pin = procread("pin",ro_pid);
			pin_locked = 1;	
			status[TOPREJECT] = "no";	
			switch(validate(FSH_VALIDPIN,pin,number))
			case "FSHIBOK":
				_fi_pinOK = 1;
				break;
			case "NONE":
				_fi_pinOK = 1;
				break;
			case "DBERR":
				sc_play(line,pr_look(DBERR,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "LNGDAYREJ":
				sc_play(line,pr_look(LNGDAYREJ,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "CMOVER":
				sc_play(line,pr_look(CMOVER,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "TOTOVER":
				sc_play(line,pr_look(TOTOVER,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "NACTIVE":
				sc_play(line,pr_look(NACTIVE,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "TDYMOVER":
				sc_play(line,pr_look(TDYMOVER,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "TDYROVER":
				sc_play(line,pr_look(TDYROVER,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
    			case "ANIMOVER":
				sc_play(line,pr_look(ANIMOVER,lang),PBMODE);
				sc_play(line,pr_look(FORASST,lang),PBMODE);
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			case "NSPIN":
				pin_locked = 0;
				sc_play(line,pr_look(INVALID,lang),PBMODE);
			default:
				sc_play(line,pr_look(INVALID,lang),PBMODE);
			endswitch
		else
			sc_play(line,pr_look(INVALID,lang),PBMODE);
		endif

		if(_fi_ctr < 4)
			sc_clrdigits(line);
			sc_play(line,pr_look(ENTERPIN2,lang),PBMODE); 
		else
			sc_play(line,pr_look(GOODBYE,lang),PBMODE);
			fsh_exit(0,0,0,FALSE,ANSRMODE);
		endif
	endfor

	if(_fi_pinOK eq 1)

		sc_play(line,pr_look(THANKYOU,lang),PBMODE);
		sc_toneint(line,1);

      		procwrit("numval",getdtmf(line,pr_look(NUMVAL,lang),1));
      		fsplog(procread("side_id",ro_pid),procread("numval",ro_pid),"io_phnum");	
		fsplog(procread("side_id",ro_pid),procread("subj_id",ro_pid),"subj_id");
		fsplog(procread("side_id",ro_pid),procread("phone_id",ro_pid),"phone_id");

		mynoiseyn = cr_query(line,pr_look(NOISEYN,lang),"12");
		procwrit("noiseyn",mynoiseyn);
		fsplog(procread("side_id",ro_pid), procread("noiseyn",ro_pid), "with_noise");

		myphntype = cr_query(line,pr_look(PHNTYPE,lang),"123");
		procwrit("phntype",myphntype);	
      		fsplog(procread("side_id",ro_pid), procread("phntype",ro_pid), "phonetype");	

		myphnset = cr_query(line,pr_look(PHNSET,lang),"1234");
		procwrit("phnset",myphnset);	
      		fsplog(procread("side_id",ro_pid), procread("phnset",ro_pid), "phoneset");		

		procwrit("namerec",recname(line,pin));
		fsplog(procread("side_id",ro_pid),procread("namerec",ro_pid),"namerec");

		sc_play(line,pr_look(HOLD,lang),PBMODE);
		toh_start = tmr_secs();
		notify("onhold");
		procwrit("ohdur",0);
		scb_route(FSH_MOH, SCB_VOX,dboard*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);	
		oh_start = tmr_secs();
		for(;;)
			ret = msg_get(2);
			if(length(ret) <> 0)
				if(strpos(ret,"X") > 0)
					mypair = substr(ret,1,strpos(ret,"X") - 1);	
					mypair_line = strend(ret,length(ret) - (length(mypair) + 1));
					voslog("OH Loop  msg_get produced:  " & ret & " MYPAIR: " & mypair & " MYPAIR_LINE: " & mypair_line);
					break;
				else
					voslog("waiting for mypair str, got some other msg_put product: " & ret);
				endif
			endif

			if(tmr_secs() - oh_start > 70)
				procwrit("ohdur",71);
				scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);

				for(ctr = 0;ctr < 5;++ctr)		
					sc_play(line,pr_look(HOLD2,lang),PBMODE);			
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
						fsh_exit(0,0,0,FALSE,ANSRMODE);
					default:
						oh_start = tmr_secs();	
						sc_clrdigits(line);
						if(ctr <= 4)
							sc_play(line,pr_look(INVALID,lang),PBMODE);
							sc_play(line,pr_look(HOLDEXIT,lang),PBMODE);
						else
							fsh_exit(0,0,0,FALSE,ANSRMODE);
						endif
					endswitch
				endfor
				scb_route(FSH_MOH, SCB_VOX,dboard*DTI_OFFSET + line, SCB_DTI, SCB_HALF_DUPLEX);
			endif
		endfor
		procwrit("ohdur",0);
		voslog(ro_pid & " is paired with " & mypair);
		scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);

		mypair_pin     = procread("pin"     , mypair);
		mypair_number  = procread("number"  , mypair);
		mypair_phntype = procread("phntype" , mypair);
		mypair_phnset  = procread("phnset"  , mypair);
		mypair_noiseyn = procread("noiseyn" , mypair);	

		##topic = gettod();
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
				fsh_exit(0,0,0,FALSE,ANSRMODE);
			endswitch
			sleep(1);
		endfor

		status[HUPB4BRIDGE] = "no";
		toh_end = tmr_secs();

		sc_toneint(line,0); ## turn off barge-in

		sc_sigctl("(");
		if(ro_pid > mypair)
			# logbrdg
			call_id = logbrdg(PROJ_FSHSPA,
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
			glb_set(ro_pid,"REC");
			reca_pid = spawn("recorder",line       ,sema,semc,fnama,FSH_RECLEN,ro_pid,"A");
			recb_pid = spawn("recorder",mypair_line,semb,semd,fnamb,FSH_RECLEN,ro_pid,"B");
			semblock(semc);
			semblock(semd);
			sem_clrall();
			scb_route(dboard*DTI_OFFSET + line, SCB_DTI, dboard*DTI_OFFSET + mypair_line, SCB_DTI, SCB_FULL_DUPLEX);
		else
			voslog(mypair & " is acting as master");
			cname = gen_commname("B");
		endif


		status[RECORDING] = 1;			
		conn_start = tmr_secs();
		lcheck = tmr_secs();
		
		scb_route(dboard*DTI_OFFSET + line,        SCB_DTI, line       , SCB_VOX, SCB_HALF_DUPLEX); 
		scb_route(dboard*DTI_OFFSET + mypair_line, SCB_DTI, mypair_line, SCB_VOX, SCB_HALF_DUPLEX); 

		sc_sigctl(")");
		
		for(;;)
			if(tmr_secs() - conn_start > FSH_RECLEN + 5)
				sc_sigctl("c");
				break;
			endif
			sc_sigctl("(");
			if(tmr_secs() > lcheck + 5)
				lcheck = tmr_secs();
				status[RUNTIME] = tmr_secs();
				status[FILESIZA] = fil_info(fnama,1);
				status[FILESIZB] = fil_info(fnamb,1);
				if(ro_pid > mypair)	
					    procwrit("filesiza",status[FILESIZA]);
					    procsend("filesiza",status[FILESIZA],mypair);
					    procwrit("filesizb",status[FILESIZB]);
					    procsend("filesizb",status[FILESIZB],mypair);
				endif
				glb_set(ro_pid,status[RUNTIME]);
			endif
			sc_sigctl(")");
		endfor
		stoprec(line);
		stoprec(mypair_line);	

		scb_route(dboard*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_play(line,pr_look(RECEND,lang),PBMODE);
		if(ro_pid > mypair)						
			scb_route(dboard*DTI_OFFSET + line, SCB_DTI, dboard*DTI_OFFSET + mypair_line, SCB_DTI, SCB_FULL_DUPLEX);
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

		sc_getdigits(line,1,60,0);
		if(substr(sc_digits(line),1,1) streq "1")
			sc_record(line, cname, 45, 10, 1792, 2);
		endif
		sc_play(line,pr_look(THANKYOU,lang),PBMODE);

		fsh_exit(0,0,0,FALSE,ANSRMODE);
	else
		sc_play(line,pr_look(GOODBYE,lang),PBMODE);
		fsh_exit(0,0,0,FALSE,ANSRMODE);
	endif

endfunc


