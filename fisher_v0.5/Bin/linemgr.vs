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

		

	for(ctr = 1;ctr <=24;++ctr)
		linestat[ctr] = "idle";
	endfor

	watchvar(&currpid,"currpid");
	watchvar(&currmsg,"currmsg");

	glb_set(1,"LINEMGR_UP");		
	for(;;)
		voslog("linemgr msg queue head nfree : " & msg_nfree()); 
		currmsg = msg_get(2);
		glb_set(1,"LINEMGRMPRC");
		vid_cur_pos(2,6);
		vid_set_attr(10,1);
		vid_print(glb_get(1));

		if(currmsg strneq "")
			currpid = msg_pid();
			voslog("Message recvd - currpid: " & currpid & " currmsg: " & currmsg);
			voslog("Current state of pidline["& currpid& "] : " & pidline[currpid]);


			switch(currmsg)
			case "request":			
				
				vid_cur_pos(4,6);
				vid_set_attr(10,1);
				vid_print("SLREQ PID" & currpid);

				pidline[currpid] = your_line();
				msg_put(currpid,pidline[currpid]);
				linstat();
			case "preq":

				vid_cur_pos(5,6);
				vid_set_attr(10,1);
				vid_print("PLREQ PID" & currpid);

				msg_put(currpid,your_line());
				linstat();
			case "release":

				vid_cur_pos(6,6);
				vid_set_attr(10,1);
				vid_print("REL PID" & currpid & " LIN" & pidline[currpid]);
				
				linestat[pidline[currpid]] = "idle";		
				pidline[currpid] = 0;
				msg_put(currpid,1);
				linstat();
			case "idle":
				if(pidline[currpid] > 0)
					voslog("line L" & pidline[currpid] & " idled by T" & currpid);
					linestat[pidline[currpid]] = currmsg;
					pidline[currpid] = 0;
				endif
				msg_put(currpid,1);
				linstat();
			case "onhold":
				fsh_vid_write("T" & currpid & " " & " L" & pidline[currpid] & " is onhold!");
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			case "inbound":
				fsh_vid_write("T" & currpid & " " & " L" & pidline[currpid] & " is inbound!");
				pidline[currpid] = procread("line",currpid);
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			case "dialer":
				pidline[currpid] = procread("line", currpid);				
				linestat[pidline[currpid]] = currmsg;
				fsh_vid_write("task " & currpid & " L" & pidline[currpid] & " is dialer!");
				msg_put(currpid,1);
				linstat();
			default:
				fsh_vid_write("linemgr unknown message! " & currmsg);
				fsh_vid_write("task " & currpid & " L" & pidline[currpid] & " is " & currmsg);
				pidline[currpid] = procread("line",currpid);
				linestat[pidline[currpid]] = currmsg;
				msg_put(currpid,1);
				linstat();
			endswitch
			currmsg = "";	
		endif



		vid_cur_pos(2,6);
		vid_set_attr(10,1);
		vid_print(glb_get(1));

		# find out how many groupings 
		# are present
		# onhold is the default
		# group
		# other group IDs can be up to
		# 12 chars long - 
		# valid group IDS other than onhold
		# are of this 
		# form: grp[0-9A-Z]{2,10}

		# Also - since there are 24 lines
		# on the platform, there can only
		# be up to 24 distinct groups
		# represented in the linestat
		# table at any given time
		# in this case (24 distinct groups),
		# noone can be paired
		pgnext = 0;
		for(ctr = 1;ctr <=24;++ctr)
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
		
		# ctr refers to an actual line ID!
		# currpair values (not indexes) are also line IDs!

		pair_idx = 1;
		for(ctr = 1;ctr <= 24;++ctr)
			if(linestat[ctr] streq "onhold")
				currpair[pair_idx] = ctr;
				++pair_idx;
			endif
			if(pair_idx >= 3)
				fsh_vid_write("Linemgr says: P1 = " & currpair[1] & " P2 = " & currpair[2]);
				msg_put(gpid(currpair[1]),gpid(currpair[2]) & "X" & currpair[2]);
				msg_put(gpid(currpair[2]),gpid(currpair[1]) & "X" & currpair[1]);

				linestat[currpair[1]] = "pp" & currpair[2];
				linestat[currpair[2]] = "pp" & currpair[1];
				
				vid_cur_pos(10,0);
				vid_set_attr(10,6);
				vid_print("Last PP: " & currpair[1] & " <-> " & currpair[2]);
				vid_set_attr(7,0);
			
				break;
			endif
		endfor	

		linstat();	
		voslog("linemgr msg queue tail nfree : " & msg_nfree()); 
		glb_set(1,"LINEMGR_UP");
		sleep(1);
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

	_ls_lpos[1] =  "1,52";
 	_ls_lpos[2] =  "1,61";
	_ls_lpos[3] =  "1,70";
 	_ls_lpos[4] =  "2,52";
 	_ls_lpos[5] =  "2,61";
 	_ls_lpos[6] =  "2,70";
 	_ls_lpos[7] =  "3,52";
 	_ls_lpos[8] =  "3,61";
 	_ls_lpos[9] =  "3,70";
 	_ls_lpos[10] = "4,52";
 	_ls_lpos[11] = "4,61";
 	_ls_lpos[12] = "4,70";
 	_ls_lpos[13] = "5,52";
 	_ls_lpos[14] = "5,61";
 	_ls_lpos[15] = "5,70";
 	_ls_lpos[16] = "6,52";
 	_ls_lpos[17] = "6,61";
 	_ls_lpos[18] = "6,70";
 	_ls_lpos[19] = "7,52";
 	_ls_lpos[20] = "7,61";
 	_ls_lpos[21] = "7,70";
 	_ls_lpos[22] = "8,52";
 	_ls_lpos[23] = "8,61";
 	_ls_lpos[24] = "8,70";

	_fh = fil_open(LINEMGR_STAT,"wcts");
	_fh2 = fil_open(GRPSET,"wcts");
	_fh3 = fil_open(GLBSTAT,"wcts");
	for(_ls_ctr = 1;_ls_ctr <= 24;++_ls_ctr)

		if(linestat[_ls_ctr] streq "outbound" and gpid(_ls_ctr) < 0)
			voslog(" dangling outbound line :: _ls_ctr " & 
	                       _ls_ctr & " linestat[_ls_ctr] " &
                               linestat[_ls_ctr] & " gpid(_ls_ctr) " & gpid(_ls_ctr));
				
			voslog("resetting to IDLE");
			linestat[_ls_ctr] = "idle"; 
		endif

		fil_putline(_fh,"Line # " & rjust(_ls_ctr,0,2) & ": " & 
                                linestat[_ls_ctr] & " used by task # " & 
                                gpid(_ls_ctr));
		
		fil_putline(_fh2,"uniq pair #" & _ls_ctr & " : " & pairgrps[_ls_ctr]); 
		vid_cur_pos(substr(_ls_lpos[_ls_ctr],1,1),substr(_ls_lpos[_ls_ctr],3,2));
		vid_set_attr(10,1);
		vid_print("L",rjust(_ls_ctr,0,2),"T",rjust(gpid(_ls_ctr),0,2),substr(linestat[_ls_ctr],1,2));
		vid_set_attr(7,0);
	endfor

		errctl(1);
	for(_ls_ctr = 0;_ls_ctr <=95;++_ls_ctr)
		_glb_ret = glb_get(_ls_ctr);
		if(_glb_ret strneq "")

			vid_cur_pos(9,_ls_ctr * 4);
			vid_print(substr(_glb_ret,1,4));
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
	for(_i = 1;_i <=24;++_i)
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
	for(yl_ctr = 13;yl_ctr <= 24;++yl_ctr)
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
	for(_gp_ctr = 1;_gp_ctr <= 48;++_gp_ctr)
		if(pidline[_gp_ctr] eq _gp_arg1)
			_gp_ret = _gp_ctr;
			break;
		endif	
	endfor
	return(_gp_ret);
endfunc
func fsh_vid_write(_fv_cont)
	voslog(date(1) & " " & time() & " LINEMGR:" & getpid() & " " & _fv_cont);
endfunc
onsignal
	restart;
end




