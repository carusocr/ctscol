// mtnf.c	Multi-Threaded Test RLL (threads start and wait)

#define STRICT
#include <stdio.h>
#include <windows.h>
#include <process.h>
#include "mtnlib.h"
#include "ntrll.h"


/*****************************/
/*	STARTUP/EXIT FUNCTIONS	 */ 
/*****************************/
DLLEXPORT void Startup(void)
{
	voslog("VOS/NT MTN RLL (rev %s) ", __DATE__);
}

DLLEXPORT void Cleanup(void)
{

	voslog("VOS/NT MTN RLL cleanup");
	//make sure there is no memory leaks
	CLEANUP_MT;
}

/*****************************/
/*		RLL FUNCTIONS		 */ 
/*****************************/

// TestMt is the function name from the RLL's .DEF file
BEGIN_MT_FUNC(TestMt, argc, argv)

	int argnr;
	DWORD dwId;
	char tmp_return_string[MAX_RETURN_STRING];

		// Log the arguments passed to the function
		voslog("Testmt(): argc = %d", argc);
		for(argnr=0; argnr<argc; argnr++)
		{
			voslog("TestFunc argv[%d] = %s", argnr, argv[argnr]);
		}

	voslog("Inside TestFunc before sleep");
	Sleep(5000);
	voslog("Inside TestFunc after sleep");

	dwId =  GetCurrentThreadId();
	voslog("currid=%d, pid=%d", dwId, mt_getpid(dwId)); 
	sprintf (tmp_return_string, "testmt=%d", dwId);

	// must use this to return correctly
	RETURN_MT(tmp_return_string);

END_MT_FUNC(TestMt)


