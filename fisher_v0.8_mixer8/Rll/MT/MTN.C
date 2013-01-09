#define RLL_INTERF_MODULE
#include "ntrll.h"
#undef RLL_INTERF_MODULE

HINSTANCE hVOSDLL;
LPSTR pszVersion = __DATE__;

FUNCINFO FuncInfo[] = 
	{
	ENTRY_FUNC, "Startup", (FARPROC) 0x6bf5,
	VAR_ARGS, "TestMt", (FARPROC) 0x2f63,
	EXIT_FUNC, "Cleanup", (FARPROC) 0x88ca,
	};

void DLLEXPORT RLLExit(void)
	{
	if(hVOSDLL)
		{
		FreeLibrary(hVOSDLL);
		hVOSDLL = NULL;
		}
	}

DWORD DLLEXPORT RLLInfo(LPSTR pszVOSDLL, LPWORD lpNrFuncs, 
			LPFUNCINFO *lpFuncInfo, LPSTR pszVer)
	{int i;
	DWORD dwError;

	*lpNrFuncs = 3;
	*lpFuncInfo = FuncInfo;
	strncpy(pszVer, pszVersion, 13);
	pszVer[13] = 0;

	fpVOSfunc = (FARPROC *)calloc(NrVosFuncs, sizeof(FARPROC));
	if (!fpVOSfunc)
		goto ErrorExit;

	if(pszVOSDLL)
		{
		hVOSDLL = LoadLibrary(pszVOSDLL);
		if(hVOSDLL == NULL)
			{
			goto ErrorExit;
			}

		for (i = 0; i < NrVosFuncs; i++)
			{
			 fpVOSfunc[i] = GetProcAddress(hVOSDLL, VOSfuncName[i]);
			 if(fpVOSfunc[i] == NULL)
				fpVOSfunc[i] = (FARPROC)NotImplemented;
			}
		}

	return (DWORD) 0;

ErrorExit:

	dwError = GetLastError();
	RLLExit();
	return dwError;
	}

int PASCAL LibMain(HANDLE hInstance, WORD wDataSeg, 
			WORD wHeapSize, LPSTR lpszCmdLine)
	{
	return 1;
	}

