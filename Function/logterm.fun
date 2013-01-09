
func logterm()
        dec
		var _rpt : 4;	
        enddec
	voslog("enter-logterm task # " & getpid());
	_rpt = fil_open(PROC & rjust(getpid(),0,2) & "\final_report","trwc");
	fil_putline(_rpt,"PID="        & getpid());
	fil_putline(_rpt,"TERMSTAT="   & procread("termstat",getpid()));
	fil_putline(_rpt,"CALL_ID="    & procread("call_id",getpid()));
 	fil_putline(_rpt,"SUBJ_ID="    & procread("subj_id",getpid()));
	fil_putline(_rpt,"SIDE_ID="    & procread("side_id",getpid()));
	fil_putline(_rpt,"CE_SUBJ_ID=" & procread("ce_subj_id",getpid()));
	fil_putline(_rpt,"CE_SIDE_ID=" & procread("ce_side_id",getpid()));
	fil_putline(_rpt,"FILASIZE="   & fil_info(procread("fnama",getpid()),1));
	fil_putline(_rpt,"FILBSIZE="   & fil_info(procread("fnamb",getpid()),1));
	fil_putline(_rpt,"FILA="       & procread("fnama",getpid()));
	fil_putline(_rpt,"FILB="       & procread("fnamb",getpid()));
	fil_putline(_rpt,"RUNTIME="    & procread("runtime",getpid()));
	fil_putline(_rpt,"TOPIC_ID="   & procread("topic_id",getpid()));
	fil_close(_rpt);
	voslog(CFIB_LOGTERM & " " & getpid() & " final_report");
        shell_wait(CFIB_LOGTERM & " " & getpid() & " final_report","-");
	voslog("exit-logterm task # " & getpid());

endfunc
 


		