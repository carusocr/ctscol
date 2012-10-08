#!D:\\Perl\\bin\\perl

use strict;
use Win32::Process qw(HIGH_PRIORITY_CLASS NORMAL_PRIORITY_CLASS STILL_ACTIVE);
use Win32::EventLog;
use Win32::Process::List;
use Win32;
use YAML qw(LoadFile DumpFile);
use DBI;
use Posix ":sys_wait_h";
use Data::Dumper;

my $vos_pid = my $vosrt = undef;
use sigtrap 'handler' => \&stopvos, 'normal-signals';

chdir('c:\fisher_v0.7\Bin');

my %erpt_tbl = ();
my $yml_init = LoadFile('c:\fisher_v0.7\bin\init.yml');

foreach my $eset(qw/vosenv eventlog/){
    foreach my $k(keys(%{ $yml_init->{$eset} })){
	if($eset =~ /vosenv/){
	    $ENV{$k} = $yml_init->{$eset}->{$k};
	}
	elsif($eset =~ /eventlog/){
	    $erpt_tbl{$k} = $yml_init->{$eset}->{$k};
	}
    }
}

my $evlh = Win32::EventLog->new("fisher_v0.7");

$evlh->Report(\%erpt_tbl);

Win32::Process::Create($vosrt,
		       $ENV{'VOSEXEC'},
		       'vos6w spawn',
		       0,
		       HIGH_PRIORITY_CLASS,
		       $ENV{'VXDIR'}) || die erpt("Failed to start vos6wd");

$vos_pid = $vosrt->GetProcessID();
my $exit_code = undef;
$vosrt->GetExitCode($exit_code);

for(;;){
    $vosrt->GetExitCode($exit_code);
    last unless $exit_code == STILL_ACTIVE;
    sleep(1);
}

$erpt_tbl{'Data'} = 'shutdown';

$evlh->Report(\%erpt_tbl);

exit;

sub stopvos {
    if(defined($vos_pid)){
	Win32::Process::KillProcess($vos_pid,0);
    }
}

sub erpt {
    my $msg = shift;
    print Win32::FormatMessage(Win32::GetLastError());
}
