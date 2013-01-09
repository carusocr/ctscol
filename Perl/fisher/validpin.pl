#!c:/perl/bin/perl.exe

use DBI;

use lib "../";
use FshPerl;
use Semfile;

my %timearry = ();
my %rej_subjid = ();
my %proc_valset = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $procid = shift;
$procid    = sprintf("%0.2d",$procid);

my $pin = shift;
my $phnum = shift;

die "Invalid proc id $procid\n" unless procvalid($procid);

unlink("$proc_dir/$procid/validate_resp") if -e "$proc_dir/$procid/validate_resp";

my $dbh = get_dbh();

load_24hrrecs($dbh,\%rej_subjid);

$sth = $dbh->prepare('select subj_id, active, calls_done, max_allowed, group_id from sre12_subj where pin=?');
$sth->execute($pin);
my ($subj_id,$active,$calls_done,$max_allowed,$group_id) = $sth->fetchrow;
$sth->finish;

if ( !defined( $subj_id )) {
    procwrite($procid,"validate_resp","NSPIN");
}
elsif ( !defined( $active ) ) {
    procwrite($procid,"validate_resp","NACTIVE");
}
elsif (exists($rej_subjid{$subj_id})){
    procwrite($procid,"validate_resp","CMOVER");
}
elsif ( $active eq 'L' ) {
    procwrite($procid,"validate_resp","LNGDAYREJ");
}
elsif ( $calls_done >= $max_allowed ) {
    procwrite($procid,"validate_resp","CMOVER");
}
elsif ( $active !~ /^[YT]$/ ) {
    procwrite($procid,"validate_resp","NACTIVE");
}
else {

    $proc_valset{'phone_id'} = get_phid($dbh,$subj_id,$phnum);
    
    set_cip($dbh,$subj_id,'Y');
    set_sut($dbh,$subj_id,'01:00');

    $proc_valset{'validate_resp'} = "FSHIBOK";
    $proc_valset{'rec_length'}    = get_reclen($dbh,"sre12");
    $proc_valset{'subj_id'}       = $subj_id;
    $proc_valset{'group_id'}      = $group_id;
    
    foreach my $proc_key(keys %proc_valset){
	procwrite($procid,$proc_key,$proc_valset{$proc_key});
    }
}

rel_dbh($dbh);

