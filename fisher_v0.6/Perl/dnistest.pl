#!c:/perl/bin/perl.exe

use Getopt::Std;
use lib "d:/fisher_v0.6/Perl/";
use lib "c:/cygwin/home/ctscoll/fisher_v0.6/Perl/";
use FshPerl;

my %opts = ();
getopt('p:t:',\%opts);

my $pid     = $opts{p};
my $teststr = $opts{t};
my $result  = -1;
my $ani     = -1;
my $dnis    = -1;

if($teststr =~ /[\*\#]{0,1}(\d+)[\*\#]+(\d+)[\*\#]{0,1}/){
    $fld_a = $1;
    $fld_b = $2;
    if(length($fld_a) > length($fld_b)){
	$ani = $fld_a;
	$dnis = $fld_b;
    }
    else {
	$ani = $fld_b;
	$dnis = $fld_a;
    }
    procwrite($pid,"dt_ani",$ani);
    procwrite($pid,"dt_dnis",$dnis);
    $result = 1;
}
procwrite($pid,"dnistest_resp",$result);
