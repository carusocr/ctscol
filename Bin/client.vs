dec

	var line: 2;
enddec

program

	
		msg_put("linemgr","request");
		line = msg_get(1);
		vid_write("Client " & getpid() & " got line: " & line);
		sleep(101);
		msg_put("linemgr","release");
		restart;

endprogram