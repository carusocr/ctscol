#!c:/perl/bin/perl.exe

use DBI;
use lib "c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl";
use FshPerl;

my $procid = shift;
$procid = sprintf("%0.2d", $procid); 

die "Invalid procid $procid\n" unless procvalid($procid);

my ($s,$mi,$h,$d,$m,$y,$dow) = (localtime)[0,1,2,3,4,5,6];
my $dstr = (qw/Su Mo Tu We Th Fr Sa/)[$dow];
my $timecond = sprintf("%%%s%%%0.2d%%",$dstr,$h);

my $dbh = get_dbh();

my %sidtbl = ();

load_tdyrec($dbh,\%sidtbl);

my $sidstr = join(",","''",keys %sidtbl);

my $sqlcmd = get_pool_qry("FULLPOOL",$timecond,$sidstr);


my @return_arry = ();

## serialize ##

run_pool_qry($dbh, \$sqlcmd, \@return_arry);

my ($subj_id,$pin,$phone_id,$number,$group_id) = @return_arry;

my %proc_valset = ();

if($pin =~ /^\d{4,5}/ && npavalid(\$number)){

    print "Returning $subj_id,$pin,$phone_id,$number,$group_id";
    set_cip($dbh, $subj_id,'Y');

    clear_excl_list($dbh,$subj_id);
    init_excl_list($dbh,$subj_id);

    $proc_valset{dbpin} = $pin;
    $proc_valset{subj_id} = $subj_id;
    $proc_valset{number} = $number;
    $proc_valset{phone_id} = $phone_id;
    $proc_valset{group_id} = $group_id;
    $proc_valset{'getcallee_resp.txt'} = sprintf("%s|%s",$pin,$number);

}
else {
    
    $pin = 'XXXX';
    $number = 'XXXXXXXXXX';

    $proc_valset{dbpin} = $pin;
    $proc_valset{number} = $number;
    $proc_valset{'getcallee_resp.txt'} = sprintf("%s|%s",$pin,$number);

}

## clear serialize ##

foreach my $proc_key(keys %proc_valset){
    procwrite($procid,$proc_key,$proc_valset{$proc_key});
}

rel_dbh($dbh);

