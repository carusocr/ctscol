#VOS example for SOCKET.DLL (IP RLL) : srvdlg.vs.

#This example task will wait for the message from any remote task and
#will participate in the message exchange "dialog" with the remote
#PC which initiated it (see clndlg.vs).
# The names "server" and "client" are used just to specify the starting
# roles of the PCs ("client", which is the remote task, initiates
# the dialog and "server", which is this task, replies).
# After the dialog started they just exchange messages on the peer-to-peer
# basis. 


dec
	var ret:127;
	var frompc:20;
	var fromtask:20;
enddec
program
	trace(8);
	ws_Trace(1);
	#name our task
	ws_SetTaskName("task_server");
	while(1)
	voslog("start getmsg ");
	# timeout in seconds 
	ret = ws_GetMsg(10);
	if(ret strneq "")
		frompc = ws_GetSenderPCName();
		if (frompc streq "") 
			voslog("can't get sender pc name");
			continue;   
		endif
		fromtask = ws_GetSenderTaskName();
		if (fromtask streq "") 
			voslog("can't get sender task name");
			continue;   
		endif
		voslog ("msg=", ret, " (", frompc, ",", "task ", fromtask, ")" );
		ret = ws_Connect(frompc, "RemPC", 1); 
		voslog("ws_conn=", ret);
		if (ret strneq 0)
			voslog(" No connection");
			sleep(20);
			exit(0);
		endif
		voslog("sending a message to client");
		ret = ws_PutMsg("RemPC", fromtask, "hi from server",1);
		voslog("PutMsg returned ", ret);
		if (ret streq "-167") #connection was reset
			voslog("Connection for ", frompc, " RemPC ", "was terminated");
		endif
	endif
	endwhile
endprogram
