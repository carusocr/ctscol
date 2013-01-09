// Include header file for MTN RLL

#ifdef __cplusplus
extern "C"
{
#endif
#define mt_func		void 

#define	MAX_RETURN_STRING	127
#define	MAX_ERROR_STRING	32
#define INVALID_PID (-1)


#define MAX_ARGC 16
#define MAX_ARGV_LENGTH 128

// errors
#define NOT_INITIALIZED			(-99)

#define OUT_OF_MEMORY			(-1)
#define OUT_OF_RANGE			(-2)
#define CREATE_EVENT_ERROR		(-3)
#define CREATE_THREAD_ERROR		(-4)
#define SET_EVENT_ERROR			(-5)
#define WAIT_OBJECT_ERROR		(-6)
#define RESET_EVENT_ERROR		(-7)
#define ALREADY_SET				(-8)
#define BAD_MEMORY				(-9)

typedef mt_func (*func_ptr)(int argc, char **argv, char *retval);
int SetupMtCall(int argc, char **argv, int pid, func_ptr MtFunc);
void TriggerLoopThreadNow(int pid);
int mt_getpid(DWORD dwThreadId);
void FreeGlobals(void);

extern BOOL bMTInitDone; // init status	
extern char mtnlib_ret_val[MAX_RETURN_STRING];

//defines a header for the user-defined function 
// to be called on the thread (body of the function follows)
#define BEGIN_MT_FUNC(FuncName, argc, argv) \
mt_func __MT_##FuncName(int argc, char **argv, char *retval) {

//defines closing '}' for the body above and creates the helper 
//t_func function which will be called directly from VOS
//in the usual RLL way. It prepares and/or starts the 
//user-defined function (which has a new header/prototype by now)
//on the thread.
#define END_MT_FUNC(FuncName) } \
t_func FuncName(int argc, char **argv)  \
	{  \
	int pid = getpid(); \
	int rc = SetupMtCall(argc, argv, pid, __MT_##FuncName); \
	if (rc != NO_ERROR) return (itoa(rc, mtnlib_ret_val, 10)); \
	suspend(); \
	TriggerLoopThreadNow(pid); \
	return ""; \
	}

//saves return value from the user-defined function in the local
//thread variable provided by the calling thread 
//to be used in the wakeup call which ends the function execution
//on the thread
#define RETURN_MT(String) \
	if(strlen(String) > MAX_RETURN_STRING)\
		String[MAX_RETURN_STRING] = 0;\
	strcpy(retval, String); \
	return;

#define CLEANUP_MT FreeGlobals();

typedef struct tag_MTARGS
	{
	unsigned PID;
	int argc;
	char **argv;
	func_ptr mt_fptr; 
	} MTARGS;

#ifdef __cplusplus
}
#endif
