

dec

	include "fisher_core.inc"
	include "fisher_common.inc"
	include "fisher_prompts.inc"

enddec

program


	ro_pid = getpid();
	msg_settaskname("mohT" & ro_pid);
	msg_flush();
	line = arg(1);
	
	if(line < MIN_SLOTNR or line > MAX_SLOTNR)
	   voslog("Critical Error: Failed to get line: invalid lineid: " & line);
           restart;
        endif
	
	glb_set(ro_pid,"MOH");
        procwrit("line",line);

	notify("moh");

	voslog(" using line " & line & " for music on hold ");
	for(;;)
		if(fil_info(FSH_MOH1,1) > 0)
                        sc_play(line,FSH_MOH1,PBMODE);
                endif
                if(fil_info(FSH_MOH2,1) > 0)
                        sc_play(line,FSH_MOH2,PBMODE);
                endif
                if(fil_info(FSH_MOH3,1) > 0)
                        sc_play(line,FSH_MOH3,PBMODE);
                endif
                if(fil_info(FSH_MOHN,1) > 0)
                        sc_play(line,FSH_MOHN,PBMODE);
                endif
        endfor

endprogram


