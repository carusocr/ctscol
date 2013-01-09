
dec

	const SCB_DTI = 3;    ## i.e. digital
	const SCB_VOX = 1;
	const SCB_FULL_DUPLEX = 0;
	const SCB_HALF_DUPLEX = 1;

	include "fisher_core.inc"
	include "fisher_prompts.inc"
	include "fisher_perl.inc"
        include "tone_prompts.inc"
	include "cfib_prompts.inc"
	include "cfib_perl.inc"
	include "cfib_recparm.inc"
	var ppid : 8;
	var line : 2;
	var calling : 17;
	var ret : 2;
        var reclen    : 5;
        var startsec  : 8;	
	var side_id   : 8;
	var _ntries   : 2;
	var _validpin : 1;
	var lang : 3;
enddec

program

	lang = ENG;
	glb_set(getpid(),"DIALOUT");
	clrproc(getpid());
	msg_settaskname("dialerT" & getpid());	
	ppid    = arg(1);
	line    = arg(2);
	calling = arg(3);
	
	tmr_start();
	
	procwrit("line",line);
	procwrit("number",calling);
	procwrit("ppid",ppid);	
	procwrit("mode","dialer");			
	notify("dialer");
	
	side_id = newside(PROJ_CFIB,calling,line,getpid());
	logval(side_id,calling,"io_phnum");
	procwrit("side_id",side_id);

	voslog("CALLING: " & calling & " LINE: " & line );
	msg_put(ppid,"calling");	

	ret = dialer_call(line,calling);

	if(ret eq 1)


		glb_set(getpid(),"DIALCONN");
		# Hello. This is the LDC's call collection Platform.

		sc_play(line,CFIB_HELLO_OB, PBMODE);

		# To accept this call, Please Press 1

		if(cr_query(line,CFIB_ACCEPT_OB,"123456789#*") streq 1)
			glb_set(getpid(),"DIALACCE");
			# Please enter your pin followed by the pound sign
			sc_play(line,CFIB_ENTERPIN,PBMODE);
			_ntries = 0;
			_validpin = FALSE;
			while(getpin() eq TRUE and _ntries < 3)
				switch(validate(CFIB_VALIDPIN,procread("pin",getpid()),procread("number",getpid())))
				case "CFIBOK":
					_validpin = TRUE;

					glb_set(getpid(),"DIALVALP");
				
					sc_play(line,CFIB_HOLD,PBMODE);

					msg_put(ppid,"connected");

					glb_set(getpid(),"RECOK");
	  				for(;;)
	  					switch(glb_get(ppid))
						case "RECOK":
							break;	
						case "HUP":
							sc_play(line,CFIB_CEHUP,PBMODE);
							dialer_exit();
						case "WAIT":
							sc_play(line,CFIB_CEHUP,PBMODE);
							dialer_exit();
						endswitch					
	  				endfor
				
					reclen   = procread("rec_length",ppid);
					startsec = procread("startsec",ppid);				

					for(;;)
						if(timesup(reclen,startsec,glb_get(ppid+24)) eq TRUE)
							break;
						endif;

		    				switch(glb_get(ppid))
		    				case "HUP":
            						break;
						case "WAIT":
							break;	    	
	    					endswitch
						procwrit("linestat",sc_stat(line));
       	  					procwrit("recbytes",sc_stat(line,STAT_NBYTES)); 
        					procwrit("sound",sc_stat(line,STAT_SILENCE)); 

					endfor

				
					sc_abort(line);
					do
						sleep(1);
					until (sc_stat(line) eq 0);

					scb_route(DTI_BOARD*DTI_OFFSET + line, SCB_DTI, line, SCB_VOX, SCB_FULL_DUPLEX);
					sc_play(line,CFIB_RECEND, PBMODE);
					break;
				default:
					procwrit("termstat","INVALIDPIN");
					sc_play(line,CFIB_INVALIDPIN, PBMODE);
					sc_play(line,CFIB_REENTERPIN, PBMODE);
        				_ntries += 1; 
				endswitch
			endwhile

			if(_validpin eq FALSE)
				msg_put(ppid,"rejected");
			endif
		else
			msg_put(ppid,"rejected");
		endif		
	endif

	sc_play(line,CFIB_GOODBYE,PBMODE);	
	
	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	clrsig(1,line);			
	sc_sigctl("c"); # clear any events, turn off event handling suspension
	dialer_exit();

endprogram

func dialer_call(arg1,arg2)
	dec
		var _line : 2;
		var _number : 17;
		var _board : 1;
		var _connected : 1;
		var _wtret : 8;
		var _getcarret : 8;
	enddec
	voslog("entret-dialer_call task # " & getpid());
	_board  = 1;
	_line   = arg1;
	_number = arg2;
	_connected = 0;

	scb_route(_board*DTI_OFFSET + _line, SCB_DTI, _line, SCB_VOX, SCB_FULL_DUPLEX);

	clrsig(_board,   _line);
		
    	DTI_clrtrans(_board, _line);
    	DTI_watch(_board,    _line, "w");
       	DTI_setsig(_board,   _line, 3); 
	_wtret = DTI_waittrans(_board,_line,"w",10);
	DTI_getsig(_board,_line);
	if(_wtret eq 6)
		sc_call(_line,_number);
		DTI_clrtrans(_board, _line);
		DTI_watch(_board,_line,"Aa");
		DTI_use(_board,_line,"a");
		_getcarret  = sc_getcar(_line);
		procwrit("getcarret",_getcarret);
		voslog(sc_cardata(_line,7));
		procwrit("pamd",sc_cardata(_line,7));	
		switch(_getcarret)
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

	else
		voslog("WAITTRANS " & _wtret);
		_connected = 0;
 		DTI_clrtrans(_board,_line);
		clrsig(_board,_line);
	endif

	if(_connected <> 1)
		voslog("Unable to connect to " & _number & " using line " & _line);
	endif
	return(_connected);
endfunc
func dialer_exit()
	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	glb_set(getpid(),"HUP");
	clrsig(1,line);	
	clrproc(getpid());		
	notify("release");	
	sc_sigctl("c"); # clear any events, turn off event handling suspension
	sleep(50);
	stop;
endfunc
onsignal
	voslog("task # " & getpid() & " onsig");
	sc_sigctl("(");
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	if(_validpin eq FALSE)
		msg_put(ppid,"rejected");
	endif
	msg_put(ppid,"HUP");
	glb_set(getpid(),"HUP");
	clrsig(1,line);			
	##clrproc(getpid());
	sc_sigctl("c"); # clear any events, turn off event handling suspension
	dialer_exit();
end
