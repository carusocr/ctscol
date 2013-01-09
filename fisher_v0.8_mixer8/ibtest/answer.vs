dec
	const SCB_DTI = 3;
	const SCB_VOX = 1;
	const SCB_FULL_DUPLEX = 0; 
	const SCB_HALF_DUPLEX = 1;
	var adinfo : 25;
	var ani : 20;
	var dnis : 8;
	var line : 2;
	var vlin : 2;
	var dboard : 1;
	var i : 2;
enddec

program	
	line = arg(1);
	dboard = arg(2);
	vlin = line * dboard;

	vid_write("Using line " & line & " waiting for a call");
	scb_route(dboard*256 + line,SCB_DTI,vlin,SCB_VOX,SCB_FULL_DUPLEX);
	DTI_clrsig(dboard,line,3);
	DTI_clrtrans(dboard,line);
	DTI_watch(dboard,line,"Aa");
	DTI_use(dboard,line,"a");
	do
		DTI_wait(dboard,line);
	until(DTI_trans(dboard,line,"A"));
	
	DTI_wink(dboard,line);
	sc_getdigits(vlin, 17, 10, 10);
	vid_write("wink on " & vlin);
	adinfo = sc_digits(vlin);
	
	vid_write("ADinfo for channel " & vlin & " " & adinfo);
	ani = substr(adinfo,2,10);
	dnis = substr(adinfo,13,4);
	
	DTI_setsig(dboard,line, 3);
	sc_playtone(line, 697, 1336, -10, -10, 50);	
	sleep(1);
	for(i = 0;i < 3;++i)
		sc_play(vlin,"breakmsg.ul",768);
		ibplay(dnis);
		ibplay(ani);
	endfor
	# .. process call ..
	# Disconnect call by setting A=B=0

	DTI_clrsig(dboard, line, 3);
	restart;

endprogram

func ibplay(_arg)
	dec
		var _ctr : 2;
	enddec	

	for(_ctr = 1;_ctr <= length(_arg);++_ctr)
		sc_play(vlin,"nc000" & substr(_arg,_ctr,1) & "ENG.ul",768);
	endfor
endfunc

onsignal
	DTI_clrsig(dboard, line, 3);
	restart;
end