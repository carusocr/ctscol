
func digiplay(line,digi)
	dec
		var _ctr : 2;
		var _cdigi : 1;
		var ncarr[0 .. 9] : 50;
	enddec	

	ncarr[0] = CFIB_NCZERO;
	ncarr[1] = CFIB_NCONE; 
	ncarr[2] = CFIB_NCTWO; 
	ncarr[3] = CFIB_NCTHREE;
	ncarr[4] = CFIB_NCFOUR;
	ncarr[5] = CFIB_NCFIVE;
	ncarr[6] = CFIB_NCSIX; 
	ncarr[7] = CFIB_NCSEVEN;
	ncarr[8] = CFIB_NCEIGHT;
	ncarr[9] = CFIB_NCNINE;

	for(_ctr = 1;_ctr <= length(digi);++_ctr)
		_cdigi = substr(digi,_ctr,1);
		sc_play(line,ncarr[_cdigi],768);
	endfor
endfunc
