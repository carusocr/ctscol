
func cfib(line,number)
  dec
    var _cr_line      : 2;
    var _cr_pid       : 8;
    var _cr_number    : 17;
    var _cr_numval    : 17;
    var _ce_line      : 2;
    var _ce_number    : 17;
    var _ce_pid       : 8;      
    var _ce_glb       : 32;
    var _reclen       : 5;
    var _startsec     : 8;
    var _cr_side_id   : 9;
    var _cr_pin       : 5;
    var _cr_subj_id   : 9;
    var _ce_side_id   : 9;
    var _ce_pin       : 5;
    var _ce_subj_id   : 9;
    var _ntries       : 1;
    var _call_id      : 12;
    var _cfib_tod     : 36;
  enddec

  voslog("enter-cfib task # " & getpid());  
  _cr_line   = line;
  _cr_number = number;
  _cr_pid    = getpid();  

  glb_set(_cr_pid,"START");	
  procwrit("termstat","START");
  tmr_start();
  
  notify("cfib");
  procwrit("number",_cr_number);

  _cr_side_id = newside(PROJ_CFIB,number,_cr_line,_cr_pid);
  procwrit("side_id",_cr_side_id);
  if(_cr_side_id < 0)
	sc_play(_cr_line,CFIB_TERMERR, PBMODE);
  	procwrit("termstat","NEWSIDEERR");
	voslog("exit-cfib task # " & _cr_pid);  
	cfibexit("NEWSIDEERR");
  endif

  sc_play(_cr_line,CFIB_HELLO_IB, PBMODE);  
  glb_set(_cr_pid,"HELLO");	
  procwrit("termstat","HELLO");		

  if(cr_query(_cr_line,CFIB_ACCEPT_IB,"123456789#*") strneq 1)
	procwrit("recaccpt",FALSE);
       procwrit("termstat","DIALREJC");
       voslog("exit-cfib task # " & _cr_pid);
       sc_play(_cr_line,CFIB_GOODBYE,PBMODE);
       cfibexit("DIALREJC");
  else
	procwrit("recaccpt",TRUE);
  endif

  sc_play(_cr_line,CFIB_ENTERPIN, PBMODE);
  glb_set(_cr_pid,"ENTERPIN");	
  procwrit("termstat","ENTERPIN");

  while(getpin() eq TRUE and _ntries < 3)
    switch(validate(CFIB_VALIDPIN,procread("pin",_cr_pid),procread("number",_cr_pid)))
    case "CFIBOK":
	glb_set(_cr_pid,"CFIBOK");
  	procwrit("termstat","CFIBOK");		
	_cr_pin = procread("pin",_cr_pid);	
        _cr_numval = _cr_number;

      	procwrit("cr_numval",_cr_numval);
      	logval(_cr_side_id,_cr_numval,"io_phnum");

        _ce_pin = getdtmf(_cr_line,CFIB_CEENTPIN,4);
	procwrit("ce_pin",_ce_pin);

        if(_ce_pin < 0)
          procwrit("termstat","PGENFAILERR");
      	  cfibexit("PGENFAILERR");	
        endif

        _ce_subj_id = pin2sid(_ce_pin,_cr_pid);

        if(procexists("ce_number",_cr_pid) eq TRUE)
      	  _ce_number = procread("ce_number",_cr_pid);
        else
	  _ce_number = getdtmf(_cr_line,CFIB_ENTERNUM,9);
        endif

      	procwrit("termstat","ENTERNUM");
      	_cr_subj_id = procread("subj_id",_cr_pid);

      	if(procexists("rec_length",_cr_pid) eq TRUE)
      	  _reclen = procread("rec_length",_cr_pid);
      	else
	  procwrit("rec_length", CFIB_MAXSECS);
	  _reclen = CFIB_MAXSECS;
      	endif

        # Please hold while we connect you to your call partner
        sc_play(_cr_line,CFIB_HOLD, PBMODE);
        procwrit("termstat","ONHOLD");

        sc_sigctl("(");
        scb_route(FSH_MOH, SCB_VOX,DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, SCB_HALF_DUPLEX);
        voslog("requesting PAIRLINE from linemgr");
        msg_flush();
        msg_put("linemgr","preq");
        _ce_line = msg_get(60);
        voslog("vos msg received from " & msg_sendername() & ", sender task nr T" & msg_pid());
        voslog("linemgr returned pairline L" & _ce_line);
 
        procwrit("ce_line",_ce_line);
        if(_ce_line < MIN_OBLINE or _ce_line > MAX_OBLINE)
           procwrit("termstat","TERMERR");
           voslog("INVALID pairline nr " & _ce_line);
	   voslog("There seems to be a problem in linemgr");
	   voslog("dialout lines should always be >= "& MIN_OBLINE & " and <= " & MAX_OBLINE);
  	   voslog("exit-cfib task # " & _cr_pid);  
	   sc_play(_cr_line,CFIB_CEHUP,PBMODE);
	   cfibexit(procread("termstat",_cr_pid));
      endif
      sc_sigctl(")");

      sc_sigctl("(");

      ## to listen to callee line activity, uncomment the following line
      scb_route(DTI_BOARD*DTI_OFFSET + _ce_line, SCB_DTI, DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, SCB_HALF_DUPLEX);

      _ce_pid = spawn("dialernp",_cr_pid,_ce_line,_ce_number);
      glb_set(_cr_pid,"NPD" & _ce_pid);	
      procwrit("ce_pid",_ce_pid);

      for(;;)
	if(glb_get(_ce_pid) streq "HUP")
		scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_play(_cr_line,CFIB_CEHUP,PBMODE);
		procwrit("termstat","CEHUP");
  		voslog("exit-cfib task # " & _cr_pid);  
		cfibexit(procread("termstat",_cr_pid));
	endif

        switch(msg_get(2))
	case "calling":
	  _ce_subj_id = procread("ce_subj_id",_cr_pid);
	  _ce_side_id = procread("side_id",_ce_pid);
	  procwrit("ce_side_id",_ce_side_id);
	  procwrit("ce_subj_id",_ce_subj_id);
        case "connected":
	  _ce_subj_id = procread("ce_subj_id",_cr_pid);
	  _ce_side_id = procread("side_id",_ce_pid);
	  procwrit("ce_side_id",_ce_side_id);
	  _call_id = logbrdg(PROJ_CFIB,_cr_subj_id,_ce_subj_id,_cr_side_id,_ce_side_id,_cr_pid);
          procwrit("call_id",_call_id);        
          scb_route(_cr_line, SCB_VOX, DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, SCB_HALF_DUPLEX);
          scb_route(_cr_line, SCB_VOX, DTI_BOARD*DTI_OFFSET + _ce_line, SCB_DTI, SCB_HALF_DUPLEX);

          # Welcome to both of you. You may begin your
                            # conversation now. 
          sc_play(_cr_line, CFIB_STARTTALK, PBMODE);
  	  procwrit("termstat","BRIDGED");

          sema = _cr_line;
          semb = _ce_line;
          semc = sema + SEM_OFFSET;
          semd = semb + SEM_OFFSET;

          sem_set(sema);
          sem_set(semb);
    
          fnam_base = LID_REC & date(1) & "_" & time() & "_" & _call_id;
          fnama = fnam_base & "_A.ul";
          fnamb = fnam_base & "_B.ul";    
	  cname = fnam_base & "_COM.ul";    
	  procwrit("fnama", fnama);
	  procwrit("fnamb", fnamb);
	  procwrit("cname", cname);    
          
          reca_pid = spawn("recorder", _cr_line, sema, semc, fnama, _reclen+10, _cr_pid, "A");
          recb_pid = spawn("recorder", _ce_line, semb, semd, fnamb, _reclen+10, _cr_pid, "B");
          semblock(semc);
          semblock(semd);
          sem_clrall();

          scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, DTI_BOARD*DTI_OFFSET + _ce_line, SCB_DTI, SCB_FULL_DUPLEX);
          scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_HALF_DUPLEX); 
          scb_route(DTI_BOARD*DTI_OFFSET + _ce_line, SCB_DTI, _ce_line, SCB_VOX, SCB_HALF_DUPLEX); 

	  _startsec = tmr_secs();

          procwrit("startsec",_startsec);

	  glb_set(_cr_pid,"RECOK");
	  for(;;)
	  	switch(glb_get(_ce_pid))
		case "RECOK":
			break;
		case "HUP":
			procwrit("termstat","NORECHUP");
  			voslog("exit-cfib task # " & _cr_pid);  
			cfibexit(procread("termstat",_cr_pid));
		endswitch
		sleep(1);
	  endfor

      	  sc_sigctl(")");	

          for(;;)

            sc_sigctl("(");
	
	    glb_set(_cr_pid+24,tmr_secs());

            if(timesup(_reclen,_startsec,glb_get(_cr_pid+24)) eq TRUE)
		voslog("_reclen: " & _reclen &
	               " _startsec: " & _startsec &
	               " glb_get(_cr_pid+24): " & glb_get(_cr_pid+24));
		voslog(" timesup is TRUE - stopping recording");
            	stoprec(_cr_line);
            	stoprec(_ce_line); 
            	break;
            endif

	    _ce_glb = glb_get(_ce_pid);
	    
	    switch(_ce_glb)
	    case "HUP":
		voslog(" _ce_glb : " & _ce_glb);
	        voslog(" callee hangup - stopping recording and exiting ");
            	stoprec(_cr_line);
            	stoprec(_ce_line); 

		scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_FULL_DUPLEX);
		sc_play(_cr_line,CFIB_CEHUP,PBMODE);

		procwrit("termstat","RECHUP");
            	break;	    	
	    endswitch

            procwrit("linestat",sc_stat(_cr_line));       
            procwrit("recbytes",sc_stat(_cr_line,STAT_NBYTES)); 
            procwrit("sound",sc_stat(_cr_line,STAT_SILENCE));
            sc_sigctl(")");	

          endfor
	  
	  sc_sigctl("(");	

	  scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_FULL_DUPLEX);
	  glb_set(_cr_pid,"RECEND");	

	  sc_play(_cr_line, CFIB_RECEND, PBMODE);
  	  sc_clrdigits(_cr_line);

	  procwrit("termstat","RECEND");  	

 	  sc_sigctl(")");	
          break;
 
       case "rejected":
	  scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_FULL_DUPLEX);
          sc_play(_cr_line,CFIB_REJECTED,PBMODE);
  	  procwrit("termstat","CEREJECT");
          break;

	case "HUP":
	  scb_route(DTI_BOARD*DTI_OFFSET + _cr_line, SCB_DTI, _cr_line, SCB_VOX, SCB_FULL_DUPLEX);
	  sc_play(_cr_line,CFIB_CEHUP,PBMODE);
	  procwrit("termstat","CEHUP");
          break;	
        default:
        endswitch
      endfor
      break;
    case "INVALID_PIN":
  	procwrit("termstat","INVALIDPIN");
	sc_play(_cr_line,CFIB_INVALIDPIN, PBMODE);
	sc_play(_cr_line,CFIB_REENTERPIN, PBMODE);
        _ntries += 1; 
    case "INACTIVE_PIN":
  	procwrit("termstat","INACTIVEPIN");
	sc_play(_cr_line,CFIB_INACTIVEPIN, PBMODE);
	sc_play(_cr_line,CFIB_FORASSIST, PBMODE);
	break;
    case "NOPAIR_SBJ":
	procwrit("termstat","NOPAIRSBJ");
	sc_play(_cr_line,CFIB_NOPAIR_SBJ, PBMODE);
	sc_play(_cr_line,CFIB_FORASSIST, PBMODE);
	break;
    case "MAX_CALLS":
	procwrit("termstat","MAXCALLS");
	sc_play(_cr_line,CFIB_MAXCALLS, PBMODE);
	sc_play(_cr_line,CFIB_FORASSIST, PBMODE);
	break;
    default:
	procwrit("termstat","TERMERR");
	sc_play(_cr_line,CFIB_TERMERR, PBMODE);
	sc_play(_cr_line,CFIB_FORASSIST, PBMODE);
        break;
    endswitch
  endwhile

  sc_play(_cr_line,CFIB_GOODBYE,PBMODE);
  voslog("exit-cfib task # " & _cr_pid);  
  cfibexit(procread("termstat",_cr_pid));  

endfunc

