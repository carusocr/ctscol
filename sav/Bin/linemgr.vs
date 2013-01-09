dec

	include "fisher_core.inc"
	include "fisher_perl.inc"
	include "linemgr_disp.inc"

	const LINEMGR_STAT = PROC & "LINEMGR\\stat.txt";
	const GRPSET = PROC & "LINEMGR\\uniqpairs.txt";
	const GLBSTAT = PROC & "LINEMGR\\glbstat.txt";
	
	var ctr : 2;
	var pgnext : 2;
	var linestat[1..24] : 14;
	var pidline[1..48] : 14;
	var currmsg : 10;
	var currpid : 4;
	var pair_idx : 1;
	var currpair[1..2] : 2;
	var pairgrps[1..48] : 14;
	
enddec

program


	#cleanup
	shell_wait(FSH_CLEARCIP,"-"); # at startup, noone should be marked CIP

	msg_settaskname("linemgr");

	for(ctr = MIN_SLOTNR;ctr <=MAX_SLOTNR;++ctr)
		linestat[ctr] = "idle";
	endfor

	watchvar(&currpid,"currpid");
	watchvar(&currmsg,"currmsg");

	glb_set(1,"LINEMGR_UP");		
	for(;;)

		currmsg = msg_get(2);
		glb_set(1,"LINEMGRMPRC");
		if(currmsg strneq "")
			currpid = msg_pid();
			
			

			switch(currmsg)
			case "request":			
				
				pidline[currpid] = your_line();
				msg_put(currpid,pidline[currpid]);
				linstat();
			case "preq":

				msg_put(currpid,your_line());
				linstat();
			case "release":

				linestat[pidline[currpid]] = "idle";		
				pidline[currpid] = 0;
				msg_put(currpid,1);
				linstat();
			case "idle":
				if(pidline[currpid] > 0)
					linestat[pidline[currpid]] = currmsg;
					pidline[currpid] = 0;
				endif
				msg_put(currpid,1);
				linstat();
			case "onhold":
				
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			case "inbound":
				
				pidline[currpid] = procread("line",currpid);
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			case "dialer":
				pidline[currpid] = procread("line", currpid);				
				linestat[pidline[currpid]] = currmsg;
				
				msg_put(currpid,1);
				linstat();
			default:
				
				pidline[currpid] = procread("line",currpid);
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			endswitch
			currmsg = "";	
		endif

		pgnext = 0;
		for(ctr = MIN_SLOTNR;ctr <= MAX_SLOTNR;++ctr)
			if(substr(linestat[ctr],1,3) strneq "grp")
				continue;
			else
				if(exists(linestat[ctr]) eq FALSE)
					pgnext += 1;
					pairgrps[pgnext] = linestat[ctr];
				endif
			endif
		endfor

		pgnext += 1;
		pairgrps[pgnext] = "onhold";
		
		# ctr refers to an actual line ID
		# currpair values (not indexes) are also line IDs

		pair_idx = 1;
		for(ctr = MIN_SLOTNR;ctr <= MAX_SLOTNR;++ctr)
			if(linestat[ctr] streq "onhold")
				currpair[pair_idx] = ctr;
				++pair_idx;
			endif
			if(pair_idx >= 3)

				msg_put(gpid(currpair[1]),gpid(currpair[2]) & "X" & currpair[2]);
				msg_put(gpid(currpair[2]),gpid(currpair[1]) & "X" & currpair[1]);

				linestat[currpair[1]] = "pp" & currpair[2];
				linestat[currpair[2]] = "pp" & currpair[1];
				
				break;
			endif
		endfor	

		linstat();	

		glb_set(1,"LINEMGR_UP");
		
	endfor	
endprogram

func linstat()
	dec	
		var _ls_ctr : 2;
		var _fh : 4;
		var _fh2 : 4;
		var _fh3 : 4;
		var _ls_lpos[1 .. 27]: 6;
		var _glb_ret : 12;
	enddec

	_fh  = fil_open(LINEMGR_STAT,"wcts");
	_fh2 = fil_open(GRPSET,"wcts");
	_fh3 = fil_open(GLBSTAT,"wcts");

	for(_ls_ctr = MIN_SLOTNR;_ls_ctr <= MAX_SLOTNR;++_ls_ctr)

		if(linestat[_ls_ctr] streq "outbound" and gpid(_ls_ctr) < 0)
			linestat[_ls_ctr] = "idle"; 
		endif

		fil_putline(_fh,"Line # " & rjust(_ls_ctr,0,2) & ": " & 
                                linestat[_ls_ctr] & " used by task # " & 
                                gpid(_ls_ctr));
		
		fil_putline(_fh2,"uniq pair #" & _ls_ctr & " : " & pairgrps[_ls_ctr]); 
	endfor

	errctl(1);
	for(_ls_ctr = 0;_ls_ctr <=95;++_ls_ctr)
		_glb_ret = glb_get(_ls_ctr);
		if(_glb_ret strneq "")
			fil_putline(_fh3,"GLB" & rjust(_ls_ctr,0,2) & " " & _glb_ret);
		endif
	endfor
	errctl(0);
	fil_close(_fh);
	fil_close(_fh2);
	fil_close(_fh3);

endfunc

func exists(arg1)
	dec
		var _used : 1;
		var _i : 2;
	enddec
	_used = FALSE;
	for(_i = MIN_SLOTNR;_i <= MAX_SLOTNR;++_i)
		if(pairgrps[_i] streq arg1)
			_used = TRUE;
			break;
		endif
	endfor
	return(_used);
endfunc

func your_line()

	dec
		var yl_ctr: 2;
		var yl_ret: 2;
	enddec
	yl_ret = 0;	
	for(yl_ctr = MIN_OBLINE; yl_ctr <= MAX_OBLINE; ++yl_ctr)
		if(linestat[yl_ctr] streq "idle")
			linestat[yl_ctr] = "outbound";
			yl_ret = yl_ctr;
			break;
		endif
	endfor
	return(yl_ret);

endfunc

func gpid(_gp_arg1)
	# determine pid from line number
	dec
		var _gp_ctr: 2;
		var _gp_ret: 2;
	enddec
	_gp_ret = -1;
	for(_gp_ctr = MIN_SLOTNR;_gp_ctr <= MAX_SLOTNR;++_gp_ctr)
		if(pidline[_gp_ctr] eq _gp_arg1)
			_gp_ret = _gp_ctr;
			break;
		endif	
	endfor
	return(_gp_ret);
endfunc

onsignal
	restart;
end




