#!c:/perl/bin/perl.exe

use DBI;

use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;
my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $proc_id = sprintf("%0.2d",shift);
my $pin = shift;
my $phnum = shift;

die "Invalid proc id $proc_id\n" unless $proc_id > 0;

unlink "$proc_dir/$proc_id/validate_resp" if -e "$proc_dir/$proc_id/validate_resp";

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $sth = $dbh->prepare( "select subj_id, active, calls_done, max_allowed, group_id,
                           IFNULL(subgroup_id,'0001_0000') from lre11_subj where pin=\'$pin\'");

$sth->execute;
my ($subj_id,$active,$calls_done,$max_allowed,$group_id,$subgroup_id) = $sth->fetchrow;
$sth->finish;

$sth = $dbh->prepare("select subj_id from lre11_subj where subgroup_id = \'$subgroup_id\'
                      and pin <> \'$pin\'");
$sth->execute;
my($ce_subj_id) = $sth->fetchrow;
$sth->finish;
if($ce_subj_id !~ /\d+/){ $ce_subj_id = '99999' }


if ( !defined( $subj_id )) {
    procwrite($proc_id,"validate_resp","INVALID_PIN");
}
elsif ( !defined( $active ) or $active ne 'Y' ) {
    procwrite($proc_id,"validate_resp","INACTIVE_PIN");
}
elsif ( !defined( $ce_subj_id )) {
    procwrite($proc_id,"validate_resp","NOPAIR_SBJ");
}
elsif ( $calls_done >= $max_allowed ) {
    procwrite($proc_id,"validate_resp","MAX_CALLS");
}
else {
    my $sth = $dbh->prepare( "update telco_subjects set cip='Y' where subj_id=?" );
    $sth->execute( $subj_id );
    $sth->finish;
    print "$subj_id $group_id $ce_subj_id\n";

    procwrite($proc_id,"validate_resp","CFIBOK");
    procwrite($proc_id,"rec_length",900);
    
    procwrite($proc_id,"subj_id",$subj_id);
    procwrite($proc_id,"group_id",$group_id);
    procwrite($proc_id,"subgroup_id",$subgroup_id);
    procwrite($proc_id,"ce_subj_id",$ce_subj_id);


    $sth = $dbh->prepare("select pin from lre11_subj where subj_id=?");
    $sth->execute($ce_subj_id);
    ($ce_pin) = $sth->fetchrow;
    $sth->finish;
    procwrite($proc_id,"ce_pin",$ce_pin);


    $sth = $dbh->prepare("select phone_number from telco_phones where subj_id=?");
    $sth->execute($ce_subj_id);
    my ($ce_phnum) = $sth->fetchrow;
    $sth->finish;  
    procwrite($proc_id,"ce_number",$ce_phnum) if $ce_phnum =~ /^(1|011)\d+$/;	

}

$dbh->disconnect;
