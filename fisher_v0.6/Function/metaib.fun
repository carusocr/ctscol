
func metaib()
	dec
		var _mib_file : 50; 
	enddec

	notify("metaib");

	_mib_file = MIB_REC & date(1) & "_" & time() & "_" & "METAIB.ul"; 

	sc_toneint(line, 0);## turn interruption by DTMF OFF
	sc_play(line,pr_look(RECMSG,lang), PBMODE); # "Please record your message after the tone"

	sc_record(line,_mib_file,3700,0,1792,2);

	sc_toneint(line, 1);## turn interruption by DTMF ON
	sc_abort(line);
	do
		sleep(1);
	until (sc_stat(line) eq 0);
	DTI_clrtrans(1,line);
	DTI_clrsig(dboard,line,3);
	notify("inbound");	
	restart;		
endfunc
