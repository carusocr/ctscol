dec
	var ctr : 2;
enddec
program

	for(ctr = 1;ctr <= 24;++ctr)
		spawn("answer",ctr,1);
	endfor

endprogram