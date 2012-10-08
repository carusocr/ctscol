
$if (CORE_INC)
$else

const CORE_INC            = "Included";
const TRUE                = 1;
const FALSE               = 0;
const MIN_BOARDNR         = 1;
const MAX_BOARDNR         = 1;
const MIN_SLOTNR          = 1;
const MAX_SLOTNR          = 24;
const MIN_IBLINE          = 1;
const MAX_IBLINE          = 12;
const MIN_OBLINE          = 13;
const MAX_OBLINE          = 22;
const FSH_CLOCK           = 23;
const FSH_MOH             = 24;
const MAX_ANIDNIS_LEN	  = 17;
const PBMODE		  = 768;
const SEM_OFFSET          = 24; # line semaphores for 1 to 24, 25 to 48
const SEM_CALLING         = 50; # limit access to DTI functions by setting semaphore
const SEM_GETCALLEE       = 51;
const DTI_OFFSET          = 256;
const DTI_BOARD           = 1;
const FSH_VER             = "0.8";
const FSH_TITLE           = "FISHER v" & FSH_VER;
const FSH_ROOT            = "c:\";
const FSH_REC             = FSH_ROOT & "vos_record\spkrid\";
const MIB_REC             = FSH_ROOT & "vos_record\metaib\";
const LID_REC             = FSH_ROOT & "vos_record\lid\";
const FSH_BASE            = FSH_ROOT & "fisher_v" & FSH_VER & "\";
const CFIB_BASE           = FSH_ROOT & "fisher_v" & FSH_VER & "\";
const PERL_EXE            = "c:\Perl\bin\wperl.exe";
const FSH_PROMPTS         = FSH_ROOT & "Prompts\current\";
const TONE_PROMPTS        = FSH_ROOT & "Prompts\tone\";
const CFIB_PROMPTS        = FSH_ROOT & "Prompts\current\";
const PROC                = "p:\proc\";
const TODDIR              = FSH_BASE & "topics\";
const TODSUMMDIR          = FSH_BASE & "topic_summ\";
const FSH_PERL            = FSH_BASE & "perl\fisher\";
const CFIB_PERL           = CFIB_BASE & "Perl\cfib\";
const FSH_RECORDINGS      = FSH_REC & "conversations\";
const FSH_COMMENTS        = FSH_REC & "comments\";
const FSH_MONOLOGUES      = FSH_REC & "monologues\";
const FSH_NAMEREC         = FSH_REC & "names\";
const FSH_PERL_EXE        = PERL_EXE & " " & FSH_PERL;
const CFIB_PERL_EXE       = PERL_EXE & " " & CFIB_PERL;
const PROJ_CFIB           = 0;
const PROJ_FSHSPA         = 1;
const PROJ_FSHENG         = 2;
const PROJ_MX3            = 3;
const PROJ_SRE12          = 3;
const ANSRMODE            = 1;
const DIALMODE            = 2;
const MIN_RECLEN          = 1920000;
const FSH_RECACCEPT       = 3;
const FSH_RECREJECT       = 2;
const BLACKLIST_FILE      = FSH_BASE & "Bin\blacklist.txt";

$endif

