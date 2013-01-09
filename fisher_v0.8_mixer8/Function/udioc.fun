
func udioc(ioctbl,side_id,field,value)
        dec
                var _cmd : 90;
        enddec

        _cmd = PERL_UDIOC & " -t " & ioctbl & " -i " & side_id & " -f " & field & " -v " & value;

        return(shell_wait(_cmd,"-"));

endfunc

