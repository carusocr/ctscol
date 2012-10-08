
func notify(_noti_str)
	dec
		var _nm_ret : 2; 
	enddec
	sc_sigctl("(");
	voslog("entret-notify task # " &getpid() & " - noti_str = " & _noti_str);
	_nm_ret = -1;

	while(glb_get(1) strneq "LINEMGR_UP")
		voslog("answer->notify PID " & getpid() & " waiting for linemgr to reset " & glb_get(1) & " <> LINEMGR_UP!");
		sleep(1);
	endwhile

	if(msg_put("linemgr",_noti_str) eq 0)
		for(;;)
			_nm_ret = msg_get(3);
			if(msg_pid() eq 1 and _nm_ret eq 1)
				voslog("answer->notify got valid response from linemgr - continuing");
				break;
			else
				voslog(" answer->notify recvd spurious message: " & _nm_ret & " from pid " & msg_pid());
				sleep(1);	
			endif
		endfor
	else
		voslog(" answer->notify msg_put failed !");
	endif

	sc_sigctl(")");
	return(_nm_ret);
endfunc
