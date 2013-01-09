#VOS example for SOCKET.DLL (IP RLL) : clndlg.vs.

# This example task will try to connect to the PC with the URL 10.0.0.82.
# If connection is established in 12 seconds, it names the remote PC
# "pc_server" (for "internal" use, this name will be used to identify
# the remote PC on the local PC) and participates in the message 
# exchange "dialog" with the remote PC if it responded (see srvdlg.vs).
# The names "server" and "client" are used just to specify the starting
# roles of the PCs ("client", which is this task, initiates
# the dialog and "server", which is the remote task, replies).
# After the dialog started they just exchange messages on the peer-to-peer
# basis. 

dec
	const ALL_TASKS=1;
	const CURRENT_TASK=2;
	var ret:120;
enddec
program
	ws_Trace(1);
	#name our task
	ws_SetTaskName("task_client" & getpid());
	ret = ws_Connect("127.0.0.1", "pc_server", 12);
	voslog("ws_conn=", ret);
	if (ret <> 0)
		voslog(" No connection");
		sleep(20);
		exit(0);
	endif
	while(1)
	sleep(20);
	voslog("sending a message to server");
	ret = ws_PutMsg("pc_server", "task_server", "hello from client", 2);
	voslog("putmsg returned ", ret);
	ret = ws_GetMsg(0); #see if got something back from the server
	voslog("received ret=", ret," from ", ws_GetSenderPCName());
	voslog ("nr msgs=", ws_GetNrPendingMsgs(ALL_TASKS), " ", 
									ws_GetNrPendingMsgs(CURRENT_TASK));
	#Don't let more than 10 messages queue for our task, 
	if (ws_GetNrPendingMsgs(CURRENT_TASK) > 10)
		ws_FlushMsgs(CURRENT_TASK);
	endif
	endwhile
endprogram
