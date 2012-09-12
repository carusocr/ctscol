dec
	var currtime : 6;
	var i : 1;
	var clock_line : 2;
enddec
program
	clock_line = arg(1);
	for(;;)
		currtime = time();
		for(i = 1;i <= 6;++i)
			switch(substr(currtime,i,1))
			case 0:
				sc_playtone(clock_line,200,250,-10,-10,3);
			case 1:
				sc_playtone(clock_line,300,350,-10,-10,3);
			case 2:	
				sc_playtone(clock_line,400,450,-10,-10,3);
			case 3:
				sc_playtone(clock_line,500,550,-10,-10,3);
			case 4:
				sc_playtone(clock_line,600,650,-10,-10,3);
			case 5:
				sc_playtone(clock_line,700,750,-10,-10,3);
			case 6:
				sc_playtone(clock_line,800,850,-10,-10,3);
			case 7:
				sc_playtone(clock_line,900,950,-10,-10,3);
			case 8:
				sc_playtone(clock_line,1000,1050,-10,-10,3);
			case 9:
				sc_playtone(clock_line,1100,1150,-10,-10,3);
			endswitch
			sleep(1);
		endfor
		sleep(1);
	endfor

endprogram