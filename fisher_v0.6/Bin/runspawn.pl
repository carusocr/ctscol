#!D:\\Perl\\bin\\perl

use Win32::Process qw(HIGH_PRIORITY_CLASS NORMAL_PRIORITY_CLASS STILL_ACTIVE);
use Win32::EventLog;
use Win32::Process::List;
use Win32;
use DBI;
use Posix ":sys_wait_h";

my $vospid = my $vosrt = undef;
use sigtrap 'handler' => \&stopvos, 'normal-signals';

$ENV{'FUNCDIR'}      = 'd:\fisher_v0.6\Function';
$ENV{'INCDIR'}       = 'd:\fisher_v0.6\Include';
$ENV{'PARDIR'}       = 'c:\vos6w\cfg';
$ENV{'VOSFONTNAME'}  = 'Courier New';
$ENV{'VOSFONTSIZE'}  = '12';
$ENV{'VOSLOGDIR'}    = 'p:\proc';
$ENV{'VOSNODIALOGS'} = 'YES';
$ENV{'VOSNOSPLASH'}  = 'YES';
$ENV{'VXDIR'}        = 'd:\fisher_v0.6\Bin';

my $evlh = Win32::EventLog->new("fisher_v0.6");
my $vosexe = 'C:\vos6w\exe\vos6w.exe';

sub erpt {
    my $msg = shift;
    print "$msg\n";
    print Win32::FormatMessage(Win32::GetLastError());
}

$evlh->Report({ Computer  => 'ATLAS',
		Source    => 'fisher_v0.6',
		EventType => EVENTLOG_INFORMATION_TYPE,
		Category  => 'CTS Collection',
		EventID   => '1',
		Data      => 'startup',
                Strings   => ''});

Win32::Process::Create($vosrt,
		       $vosexe,
		       'vos6w spawn',
		       0,
		       HIGH_PRIORITY_CLASS,
		       'd:\fisher_v0.6\bin') || die erpt("Failed to start vos6wd");

my $vos_pid = $vosrt->GetProcessID();
my $exit_code = undef;
$vosrt->GetExitCode($exit_code);

for(;;){
    $vosrt->GetExitCode($exit_code);
    last unless $exit_code == STILL_ACTIVE;
    sleep(1);
}

$evlh->Report({ Computer  => 'ATLAS',
		Source    => 'fisher_v0.6',
		EventType => EVENTLOG_INFORMATION_TYPE,
		Category  => 'CTS Collection',
		EventID   => '1',
		Data      => 'shutdown',
                Strings   => ''});


exit;

sub stopvos {
    if(defined($vosrt)){
	$vosrt->Kill(0);
    }
}


