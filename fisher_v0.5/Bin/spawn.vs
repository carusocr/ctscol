dec
	include "fisher_core.inc"
	include "fisher_prompts.inc"
	var ctr : 2;
enddec
program

	
	

	vid_set_attr(7,9);
	vid_scroll_area(11,0,80,12);
	vid_box(0,0,30,10);
	vid_box(0,30,20,10);	
	vid_box(0,50,30,10);

	vid_cur_pos(1,35);
	vid_set_attr(12,8);
	vid_print(FSH_TITLE);
	vid_cur_pos(3,35);
	vid_print("SD:" & date(1));
	vid_cur_pos(4,35);
	vid_print("ST:  " & time());

	vid_set_attr(7,0);

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
		sleep(1);
		spawn("answer",ctr);
	endfor

	for(ctr = 1;ctr <= 8;++ctr)
		sleep(1);
		spawn("run_one","ENG",PROJ_MX3);
	endfor

	for(;;)
		if(fil_info(FSH_MOH1,1) > 0)
			sc_play(48,FSH_MOH1,768);
		endif
		if(fil_info(FSH_MOH2,1) > 0)
			sc_play(48,FSH_MOH2,768);
		endif
		if(fil_info(FSH_MOH3,1) > 0)
			sc_play(48,FSH_MOH3,768);
		endif
		if(fil_info(FSH_MOHN,1) > 0)
			sc_play(48,FSH_MOHN,768);
		endif
	endfor

endprogram







