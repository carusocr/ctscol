dec
	include "fisher_core.inc"
	include "fisher_prompts.inc"
	var ctr : 2;
enddec
program

	glb_set(1,"LINEMGR_DOWN");

	spawn("linemgr");
	
	for(;;)
		if(glb_get(1) streq "LINEMGR_UP")
			break;
		else
			sleep(1);
		endif
	endfor

	for(ctr = 1;ctr <= 12;++ctr)
		spawn("answer",ctr);
	endfor

	spawn("clock", 23);
	spawn("runmoh",24);

	for(ctr = 1;ctr <= 6;++ctr)
		spawn("run_one","ENG",PROJ_SRE12);
	endfor

endprogram







