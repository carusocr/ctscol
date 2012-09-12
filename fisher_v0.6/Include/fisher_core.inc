
$if (CORE_INC)
$else

const CORE_INC            = "Included";
const TRUE                = 1;
const FALSE               = 0;
const DTMF_DURATION       = "0.54945";
const MIN_BOARDNR         = 1;  # this system has one board installed
const MAX_BOARDNR         = 1;  # this system has one board installed
const MIN_SLOTNR          = 1;  # this system has 48 timeslots
const MAX_SLOTNR          = 48; # this system has 48 timeslots
const PBMODE		  = 768;
const SEM_OFFSET          = 24;
const DTI_OFFSET          = 256;
const DTI_BOARD           = 1;
const FSH_VER             = "0.6";
const FSH_TITLE           = "FISHER v" & FSH_VER;
const FSH_REC             = "d:\vos_record\spkrid\";
const MIB_REC             = "d:\vos_record\metaib\";
const LID_REC             = "d:\vos_record\lid\";
const FSH_BASE            = "d:\fisher_v" & FSH_VER & "\";
const CFIB_BASE           = "d:\fisher_v" & FSH_VER & "\";
const LDC_REJLIST         = FSH_BASE & "rejlist.txt";
const PERL_EXE            = "d:\Perl\bin\wperl.exe";
const FSH_PROMPTS         = FSH_BASE & "Prompts\current\";
const TONE_PROMPTS        = FSH_BASE & "Prompts\tone\";
const CFIB_PROMPTS        = FSH_BASE & "Prompts\current\";
const PROC                = "p:\proc\";
const TODDIR              = FSH_BASE & "topics\";
const TODSUMMDIR          = FSH_BASE & "topic_summ\";
const GLB_PERL            = FSH_BASE & "perl\";
const FSH_PERL            = FSH_BASE & "perl\fisher\";
const CFIB_PERL           = CFIB_BASE & "Perl\cfib\";
const FSH_RECORDINGS      = FSH_REC & "conversations\";
const FSH_COMMENTS        = FSH_REC & "comments\";
const FSH_MONOLOGUES      = FSH_REC & "monologues\";
const FSH_NAMEREC         = FSH_REC & "names\";
const FSH_PERL_EXE        = PERL_EXE & " " & FSH_PERL;
const CFIB_PERL_EXE       = PERL_EXE & " " & CFIB_PERL;
const DNISTEST            = PERL_EXE & " " & GLB_PERL & "dnistest.pl"; 
const PROJ_CFIB           = 0;
const PROJ_FSHSPA         = 1;
const PROJ_FSHENG         = 2;
const PROJ_MX3            = 3;
const PROJ_RATS           = 4;

$endif

