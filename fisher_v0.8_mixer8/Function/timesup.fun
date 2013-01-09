func timesup(reclen,startsec,currsec)

	if(currsec - startsec > reclen + 10)
		return(TRUE);
	else
		return(FALSE);
	endif

endfunc