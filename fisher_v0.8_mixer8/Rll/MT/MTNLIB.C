// This file serves as a set of library functions for providing
// multi-threading to VOS RLLs.

#define STRICT
#include <stdio.h>
#include <windows.h>
#include <process.h>
#include "mtnlib.h"
#include "ntrll.h"

// for error return in macro mt_func
char mtnlib_ret_val[MAX_RETURN_STRING]; 

BOOL bMTInitDone = FALSE;		// init status	
// global arrays to be allocated depending on number of tasks
MTARGS *MtArgs;		// args, index is VOS task nr (pid)
DWORD *dwThreadIds;	// thread ids, index is VOS task nr (pid)
HANDLE *hEvents;	// events handles, index is VOS task nr (pid)
char   ***gargv;	// global pool of arguments for all the tasks

// standard definition for the thread function required by _beginthreadex
unsigned int __stdcall CallMtFunc(void *);  

/*****************************/
/*	UTILITY FUNCTIONS		 */ 
/*****************************/

// Get vos task nr from within the mt function.
// Cannot use regular getpid() when inside mt function
int mt_getpid(DWORD dwThreadId)
{
	int pid;

	for (pid=0; pid < MAX_TASKS; pid++)
	{
		if (dwThreadIds[pid] == dwThreadId)
			return pid;
	}
	return INVALID_PID;
}

// get our own copy of argv[] for the thread
char **get_local_argv(int argc, char **argv, int pid)
{
int ArgCnt,ArgLen;
char **largv;

	largv = gargv[pid];
	if (largv == NULL)
		goto MemoryCorrupted;
	// make a copy of the argv in largv
	for (ArgCnt=0; ArgCnt<argc; ArgCnt++)
	{
		ArgLen = strlen(argv[ArgCnt]);
		if (largv[ArgCnt] == NULL)
			goto MemoryCorrupted;
		strcpy(largv[ArgCnt], argv[ArgCnt]);
	}
	return largv;

MemoryCorrupted:
	MessageBox(NULL, "Memory corruption: RLL local argv", "MT RLL", MB_OK);
	return NULL;
}

// allocate global pool of memory for MAX_TASKS
char ***alloc_global_argv(void)
{
	int pid, argc;
	char **targv;  // temporary argv

	gargv = (char ***) calloc(MAX_TASKS, sizeof(char **));
	if (gargv == NULL)
		goto OutOfMemory;

	for (pid = 0; pid < MAX_TASKS; pid++)
	{
		targv = (char **)calloc(MAX_ARGC, sizeof(char *));
		if (targv == NULL)
			goto OutOfMemory;
		for (argc=0; argc < MAX_ARGC; argc++)
		{
			targv[argc]=calloc(MAX_ARGV_LENGTH, sizeof (char));
			if (targv[argc] == NULL)
				goto OutOfMemory;
		}
		gargv[pid] = targv;
	}
	return gargv;

OutOfMemory:
	MessageBox(NULL, "Out of memory: RLL global argv", "MTN RLL", MB_OK);
	return NULL;
}

// free global pool of memory for MAX_TASKS
void free_global_argv(void)
{
	int pid, argc;
	char **targv;  // temporary argv

	for (pid = 0; pid < MAX_TASKS; pid++)
	{
		targv = gargv[pid];
		for (argc=0; argc < MAX_ARGC; argc++)
		{
			free(targv[argc]);
		}
		free (targv);
	}
	free(gargv);
}

int AllocateGlobals(void)
{
	MtArgs =   (MTARGS *)calloc(MAX_TASKS, sizeof(MTARGS));
	dwThreadIds = (DWORD *)calloc(MAX_TASKS, sizeof(DWORD));
	hEvents =  (HANDLE *)calloc(MAX_TASKS, sizeof(HANDLE));
	gargv = alloc_global_argv();
	if (!MtArgs || !dwThreadIds || !hEvents || !gargv)
		return OUT_OF_MEMORY;
	else
		return NO_ERROR;
}

void FreeGlobals(void)
{
	if (!MtArgs || !dwThreadIds || !hEvents || !gargv || !bMTInitDone)
		return;
	free_global_argv();
	free(hEvents);
	free(dwThreadIds);
	free (MtArgs);
}


// make sure we can trust our PIDs
void InvalidatePID(void)
{
	int pid;

	for (pid=0; pid < MAX_TASKS; pid++)
		MtArgs[pid].PID = INVALID_PID;
}

//a way to report Windows error (e.g. failure to set event) to VOS task
void WakeAfterWindowsError(int MyError, int pid)
{
	char error_return[MAX_ERROR_STRING];
	DWORD dwRC;

	dwRC = GetLastError();
	voslog("MTN Error: PID=%d, Windows Error=%d, MTN error %d",
			pid, dwRC, MyError);

	wakeup(pid, itoa(MyError, error_return, 10));
}

// INIT

//Create and start new thread
int InitializeThread(int pid)
{
	DWORD dwThreadID;
	HANDLE hEvt, hThread;
	DWORD dwError;

	// create events to wait for for our thread
	hEvt = CreateEvent( NULL,	// security
						TRUE,   // manual
						FALSE,	// non-signalled
						NULL);  // no name
	if (!hEvt)
	{
		dwError = GetLastError();
		voslog ("MTN error: Cannot create event %d. Init Failed with error %ld.", 
										pid, dwError);
		return(CREATE_EVENT_ERROR);
	}
	else
		hEvents[pid]  = hEvt;  // save our event
	
	MtArgs[pid].PID = pid;  // original pid for waitsingleobj
	MtArgs[pid].argc = 0;	// not used here
	MtArgs[pid].argv = NULL;// not used here

	// Create threads for our tasks
	hThread = (HANDLE) _beginthreadex(
		NULL,					// security
		0,						// stack_size
		CallMtFunc,				// start_address
		(LPVOID) &MtArgs[pid],	// arglist
		0,						// start immediately
		&dwThreadID);			// thrdaddr
	if(!hThread)
	{
		dwError = GetLastError();
		voslog ("MTN error: Cannot create thread %d. Init Failed with error %ld.", 
										pid, dwError);
		return(CREATE_THREAD_ERROR);
	}
	else // remember our thread id, needed for mt_getpid
		dwThreadIds[pid] = dwThreadID; 

	return(NO_ERROR);
}

// When the new thread is created, this function is called.
unsigned int __stdcall CallMtFunc(void *vp)
{
	int pid;
	func_ptr fptr; // pointer to RLL function to be called on the thread
	MTARGS *lpMtArgs = vp; 
	char szReturn[MAX_RETURN_STRING+1]; 
	DWORD dwRC;
	HANDLE hEvt;  

	if (!lpMtArgs)
	{
		voslog("CallMtFunc(): Error! vp==NULL");
		MessageBox(NULL, "Fatal error 0001", "MTN RLL", MB_OK);
// There's no way to recover from this, just give up & return
		return 911;
	}

// Need to be 100% sure of PID because we need it to do wakeup.
	pid = lpMtArgs->PID;
	if ((unsigned)pid >= MAX_TASKS)
	{
		voslog("CallMtFunc(): Error! PID=%u, MAX_TASKS=%d",
			pid, MAX_TASKS);
		MessageBox(NULL, "Fatal error 0002", "MTN RLL", MB_OK);
// There's no way to recover from this either, just give up & return
		return 911;
	}
	
	hEvt = hEvents[pid];   // get evt handle for our task

	// main loop, thread never exits until VOS exits
	while(TRUE) 
	{
		// wait for request from the RLL function
		dwRC = WaitForSingleObject(hEvt, INFINITE);
		if (dwRC == WAIT_FAILED)
		{
			WakeAfterWindowsError(WAIT_OBJECT_ERROR, pid);
			return 911;
		}

		// restore event status for next call 
		dwRC = ResetEvent(hEvt); 
		if (!dwRC)
		{
			WakeAfterWindowsError(RESET_EVENT_ERROR, pid);
			return 911;
		}

		fptr = lpMtArgs->mt_fptr; // RLL function
		if (fptr == NULL)
		{
		voslog("MTN: Error- no fptr to call on the thread, PID=%d",
			pid);
			MessageBox(NULL, "Fatal error 0003", "MTN RLL", MB_OK);
	// There's no way to recover from this either, just give up & return
			return 911;
		}

		//Call our RLL function
		//The return string is copied in szReturn inside this
		//user-defined function by MT_RETURN macro
		(*fptr)(lpMtArgs->argc,lpMtArgs->argv, szReturn);

	// Tell VOS to wake-up the task that called us (RLL func)
	// WARNING: szReturn must be a local variable, if it's global
	// it will be shared by all threads and could be overwritten
	// by another thread before these statements are completed.
		wakeup(pid, szReturn);
		// loop back to wait for next event
	}  // while 
	return 0;  // never reached
}

// prepare multi-threaded call
int SetupMtCall(int argc, char **argv, int pid, func_ptr MtFunc)
{
	char **largv;
	int rc;

	if ((unsigned)pid > MAX_TASKS)
	{
		voslog("MTN error: PID %d out of range.", pid);
		return(OUT_OF_RANGE);
	}
	if (bMTInitDone == FALSE)  // see if very 1st MT call
	{
		// allocate our data structures
		rc = AllocateGlobals();
		if (rc != NO_ERROR)
		{
			voslog ("MTN error: Out of memory allocating globals");
			return(rc);
		}
		InvalidatePID();  // invalidate pid for all tasks
		bMTInitDone = TRUE;
	}

	// if no thread started yet for this pid, start it
	if (MtArgs[pid].PID == INVALID_PID)
	{
		rc = InitializeThread(pid);
		if (rc != NO_ERROR)
		{
			voslog ("MTN error: Cannot initialize thread for pid %d", pid);
			return(rc);
		}
	}

    // Note: alloc done just once during 1st mt call

	// get local space for the thread arguments
	largv = get_local_argv(argc, argv, pid);
	if (!largv)		// get failed
	{
		voslog("MTN error: cannot get local argument space.");
		return(BAD_MEMORY);
	}

// Store the arguments and PID for the multi-threading function
	MtArgs[pid].PID = pid;
	MtArgs[pid].argc = argc;
	MtArgs[pid].argv = largv;
	MtArgs[pid].mt_fptr = MtFunc;

	return NO_ERROR;
}

// start new iteration in the infinite thread loop for the task
void TriggerLoopThreadNow(int pid)
{
	BOOL bResult;

	bResult = SetEvent(hEvents[pid]);// start the loop now
	if (!bResult)  // couldn't set the event
		WakeAfterWindowsError(SET_EVENT_ERROR, pid);
}

