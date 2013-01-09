
# _call_id = logbrdg(_cr_subj_id,_ce_subj_id,_cr_side_id,_ce_side_id,getpid());        

func logbrdg(proj,arg1,arg2,arg3,arg4,arg5)
        dec
		var _script : 80;
        enddec
	voslog("enter-logbrdg task # " &getpid());
	switch(proj)
	case PROJ_CFIB:
	      	_script = CFIB_LOGBRIDGE;
	        voslog(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5);
        	shell_wait(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5,"-");
	case PROJ_FSHSPA:
              _script = FSHSPA_LOGBRIDGE;
	      voslog(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5);
              shell_wait(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5,"-");
 	case PROJ_FSHENG:
	      _script = FSHENG_LOGBRIDGE;
 	      voslog(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5);
              shell_wait(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5,"-");
	case PROJ_MX3:
	      _script = MX3_LOGBRIDGE;
 	      voslog(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5);
              shell_wait(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5,"-");
	case PROJ_SRE12:
	      _script = SRE12_LOGBRIDGE;
 	      voslog(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5);
              shell_wait(_script & " " & arg1 & " " & arg2 & " " & arg3 & " " & arg4 & " " & arg5,"-");
      	default:
              voslog("logbrdg error : no such project " & proj);
      	endswitch

        return(procread("logbridge_resp",getpid()));

endfunc