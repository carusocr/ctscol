dec

	include "fisher_core.inc"

	var currtime   : 6;
	var i          : 1;
	var v          : 1;
	var ro_pid     : 4;
	var line       : 2;
	var tpa[0..9]  : 4;
	var tpb[0..9]  : 4; 

enddec

program
	
	ro_pid = getpid();
	msg_settaskname("clkT" & ro_pid);
	msg_flush();

	line = arg(1);
	
	if(line < MIN_SLOTNR or line > MAX_SLOTNR)
	   voslog("Critical Error: Failed to get line: invalid lineid: " & line);
           restart;
        endif
	
	glb_set(ro_pid,"CLK");
        procwrit("line",line);
	notify("clk");
	voslog(" using line " & line & " for clock ");

	tpa[0] =  849;
	tpa[1] =  926;
	tpa[2] = 1011;
	tpa[3] = 1105;
	tpa[4] = 1209;
	tpa[5] = 1336;
	tpa[6] = 1477;
	tpa[7] = 1633;
	tpa[8] = 1805;
	tpa[9] = 1994;

	tpb[0] =  325;
	tpb[1] =  388;
	tpb[2] =  432;
	tpb[3] =  466;
	tpb[4] =  495;
	tpb[5] =  521;
	tpb[6] =  547;
	tpb[7] =  572;
	tpb[8] =  598;
	tpb[9] =  626;

	for(;;)
		currtime = time();
		for(i = 1;i <= 6;++i)
		      v = substr(currtime,i,1);
		      sc_playtone(line,tpa[v],tpb[v],-5,-5,3);
		      sleep(1);    	
		endfor
	endfor

endprogram