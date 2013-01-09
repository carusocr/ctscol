
dec

	include "fisher_core.inc"
	var board              :   1;
	var line               :   2;
	var sem1               :   2;
	var sem2               :   2;
	var max_len            :   6;
	var master_pid         :   3;
	var ab_status          :   1;
	var record_retcode     :   8;
	var sc_stat_ret[0..12] :   4;
	var file               : 100;

enddec

program

	board = 1;
	line  = arg(1);
	sem1  = arg(2);
	sem2  = arg(3);
  	file  = arg(4);
	max_len = arg(5);
	master_pid = arg(6);
	ab_status = arg(7);

	voslog("RECSTART: [" &   
	       "task="      & master_pid & "|" &  
               "abst="      & ab_status  & "|" &  
               "sem1="      & sem1       & "|" &  
               "sem2="      & sem2       & "|" &  
	       "line="      & line       & "|" &  
               "file="      & file       & "|" &  
               "maxl="      & max_len    & "]"   );

	file = strstrip(file,"#");
	file = strstrip(file," ");
	file = strstrip(file,"*");
	procwrit("recorder",date() & time() & ":recording");
	procwrit("mode","recorder");
	procwrit("ppid",master_pid);

	update_master(master_pid,"rec" & ab_status,date() & time() & ":recording");	

	vid_cur_pos(1,line);
	vid_set_attr(12,0);
	vid_print("*");

    	sc_toneint(line, 0);
	sem_set(sem2);
	sem_set(sem1);
	record_retcode = sc_record(line,file,max_len,0,1792,0);
	##record_retcode = sc_record(line,file,0,200,1792,0);

	vid_cur_pos(1,line);
	vid_set_attr(14,8);
	vid_print("_");
	voslog("sc_record line: "& line &" file: "& file &" return_code:"& record_retcode);
	vid_set_attr(7,0);
    	sc_clrdigits(line);
    	sc_toneint(line, 1);
	sem_clrall();
	clear_master(master_pid,"rec" & ab_status);
	
endprogram

func update_master(_mp,_up_fil,_up_cont)
	dec
		var _up_fh : 8;
	enddec
	_up_fh = fil_open(PROC & rjust(_mp,0,2) & "\" & _up_fil,"trwc");
	fil_putline(_up_fh, _up_cont);
	fil_close(_up_fh);
endfunc

func clear_master(_cm_mp,_cm_fil)
	fil_delete(PROC & rjust(_cm_mp,0,2) & "\" & _cm_fil);	
endfunc




