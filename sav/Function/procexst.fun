func procexst(_fpr_fil,_fpr_pid)
        dec        
        
        enddec            
	voslog("entret-procexst task # " &getpid());
        if(fil_info(PROC & rjust(_fpr_pid,0,2) & "\" & _fpr_fil,1) > 0)
        	return(TRUE);
        else
          return(FALSE);
        endif

endfunc