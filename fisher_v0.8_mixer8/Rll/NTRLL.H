// ntrll.h	VOS/NT Runtime Link Library Header For C Interface
#ifdef __cplusplus
extern "C"
{
#define t_func		extern "C" LPCSTR DLLEXPORT

#else

#define t_func		LPCSTR DLLEXPORT

#endif

#include <windows.h>

#define DLLEXPORT	__declspec(dllexport)
#define VAR_ARGS	(-1)
#define ENTRY_FUNC	(-2)
#define EXIT_FUNC	(-3)
#define MT_FUNC		(-4)	// Multi-threaded RLL function

#define MAX_RLLS		 32
#define MAX_RLL_FUNCS	251
#define MAX_LIB_NAME	  9	
#define MAX_VER_STR		 13
#define MAX_TASKS		1024

typedef struct tag_FUNCINFO
	{
	int NrArgs;
	LPSTR FuncName;
	FARPROC FuncAddr;
	} FUNCINFO, *LPFUNCINFO;	

typedef struct tag_IBLIB
	{
	char name[MAX_LIB_NAME+1];
	char ver[MAX_VER_STR+1];
	} IBLIB, *LPIBLIB;

typedef struct tag_RLLINFO
	{
	HINSTANCE hDLL;
	FARPROC fpExit;
	int NrFuncs;
	IBLIB ibLib;
	} RLLINFO, *LPRLLINFO;

		
// VOS Call-back functions

#ifdef RLL_INTERF_MODULE
char *VOSfuncName[] = { "cksent",
						"getpid",
						"suspend",
						"suspterm",
						"wakeup",
						"hangup",
						"voslog",
						"vid_write",
						"deventf",
						"ueventf",
						"hangup_t",
					  };

int NrVosFuncs = sizeof(VOSfuncName)/sizeof(char *);

FARPROC *fpVOSfunc; //array of pointers to vos call-backs

//This func is included only once in mkntrll 
//generated file.
void NotImplemented(void)
{
	int FuncNr;
	static char MsgStr[511]; //max length now is 11*9 (nr cb funcs)*(MAX_LIB_NAME)

	strcpy(MsgStr, "RLL needs function(s) which require a newer version of VOS:\n");
	for (FuncNr = 0; FuncNr < NrVosFuncs; FuncNr++)
	{
		if(fpVOSfunc[FuncNr]==(FARPROC)NotImplemented)
		{
			char *Name = VOSfuncName[FuncNr];
			if (strlen(MsgStr) + strlen(Name) + 2 > sizeof(MsgStr))
				break;
			strcat(MsgStr, Name);
			strcat(MsgStr, " ");
		}
	}

	MessageBox(NULL, MsgStr, NULL, MB_OK);
	return;
}

#else 
 
extern FARPROC *fpVOSfunc;

typedef unsigned (*UNSIGNED_UNSIGNED)(unsigned uType);
typedef unsigned (*UNSIGNED_VOID)(void);
typedef int	 (*INT_UNSIGNED)(unsigned chan);
typedef int	 (*INT_VOID)(void);
typedef int  (*INT_UNSIGNED_LPSTR)(unsigned uPID, LPSTR pszRetCode);
typedef void (*VOID_LPCSTR_)(LPCSTR,...);
typedef void (*VOID_FARPROC)(void (*fpHandler)());

#define cksent		(*(UNSIGNED_UNSIGNED)	fpVOSfunc[0])
#define getpid		(*(UNSIGNED_VOID)		fpVOSfunc[1])
#define suspend		(*(INT_VOID)			fpVOSfunc[2])
#define suspterm	(*(INT_UNSIGNED)		fpVOSfunc[3])
#define wakeup		(*(INT_UNSIGNED_LPSTR)	fpVOSfunc[4])
#define hangup		(*(INT_UNSIGNED)		fpVOSfunc[5])
#define voslog		(*(VOID_LPCSTR_)		fpVOSfunc[6])
#define vid_write	(*(VOID_LPCSTR_)		fpVOSfunc[7])
#define deventf		(*(VOID_FARPROC)		fpVOSfunc[8])
#define ueventf		(*(VOID_FARPROC)		fpVOSfunc[9])
#define hangup_t	(*(INT_UNSIGNED)		fpVOSfunc[10])

#endif

#ifdef __cplusplus
}
#endif

