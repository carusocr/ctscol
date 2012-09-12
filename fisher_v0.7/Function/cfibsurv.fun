
func cfibsurv(call_id,dbfield,value)
        dec
                var _cmd : 90;
        enddec
        voslog("entret-logval task # " & getpid());
        voslog(call_id & " " & value & " " & dbfield);
        _cmd = CFIB_LOGSURVEY & " " & call_id & " " & dbfield & " " & value;
        voslog(_cmd);
        return(shell_wait(_cmd,"-"));

endfunc

