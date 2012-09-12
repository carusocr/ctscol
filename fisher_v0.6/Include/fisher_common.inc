
$if (COMMON_INC)
$else

const COMMON_INC          = "Included";

const SCB_DTI = 3;    ## i.e. digital
const SCB_VOX = 1;
const SCB_FULL_DUPLEX = 0;
const SCB_HALF_DUPLEX = 1;
const FSH_CLOCK = 47;
const FSH_MOH   = 48;
const FSH_RECLEN = 600;
const RECORDING = 1;
const RUNTIME = 2; 
const FILESIZA = 3;
const FILESIZB = 4;
const POSANSR = 5; 
const POSPIN = 6;  
const HUPB4BRIDGE = 7;
const SHORTREC = 8;
const FULLREC = 9; 
const EMPTYKUE = 10;	
const POSOFFHOOK = 11;
const SUCCESS = 12;
const NOREC = 13;   
const TOPREJECT = 14;
const TOHTIME = 15;
const CURRPID = 16;
const CURRLINE = 17;
const GETCERET = 18;
const DIALOUTRET = 19;
const POSANSRRET = 20;
const ATTBRDG = 21;
const TERMSTAT = 22;
const ORCLSTAT = 23;
var start_time : 25;
var log_times[1..4] : 25;
const LOG_START = 1;
const LOG_ONHOLD = 2;
const LOG_END = 3;
var fisher_call_status[1..10] : 25;
const FISHER_CALL_WAITTRANS = 1;
const FISHER_CALL_GETSIG = 2;
const FISHER_CALL_GETCAR = 3;
const FISHER_CALL_CARDATA = 4;
const FISHER_CALL_PAMD = 5;
const FISHER_GETCALLEE_RSLT = 6;
const FISHER_POSANSR_RSLT = 7;
const FISHER_ATT_BRDG = 8;
const FISHER_TERM_STAT = 9;
const FISHER_ORCL_UD = 10;
const M1 = 1;
const M2 = 2;
const M3 = 3;
const M4 = 4;
const M5 = 5;
const M6 = 6;
const M7 = 7;
const M8 = 8;
const M9 = 9;
var status[1..23] : 25;
var mileston[1 .. 9] : 5;
var breakpt[1..25] : 8;
var sema : 2;
var semb : 2;
var semc : 2;
var semd : 2;
var dboard : 2;
var fnama : 90;
var cname : 94;
var fnamb : 90;
var fnam_base : 84;
var ctr : 2;
var pin : 5;

var line : 2;
var ret : 25;
var topic : 50;
var todsumm : 50;
var mypair : 6;
var mypair_line : 2;
var mypair_pin : 5;
var mypair_number : 13;
var myphntype : 1;
var myphnset : 1;
var mypair_phntype : 1;
var mypair_phnset : 1;
var conn_start : 8;
var toh_start : 8;
var toh_end : 8;	
var b_end : 8;
var oh_start : 8;

var pin_locked : 1;
var reca_pid : 4;
var recb_pid : 4;

$endif

