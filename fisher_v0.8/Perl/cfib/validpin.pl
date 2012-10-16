#!c:/perl/bin/perl.exe

use DBI;

# use lib "d:/fisher_v0.8/Perl/";
use lib "c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl/";
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


# my $sth = $dbh->prepare( "select subj_id, active, calls_done, max_allowed, group_id,
                           # IFNULL(subgroup_id,'0001_0000') from lre11_subj where pin=\'$pin\'");

my $sth = $dbh->prepare( "SELECT p.id AS participant_id, p.active, COUNT(DISTINCT a.conversation_id), p.max_conversations_allowed
                          FROM participants p
                          JOIN audio_objects a ON p.id = a.participant_id
                          JOIN $lui{database}.enrollments e ON p.enrollment_id = e.id
                          JOIN $lui{database}.collections c ON e.collection_id = c.id
                          WHERE p.pin = $pin AND c.name = \'$collection{name}\'");

$sth->execute;
# my ($subj_id,$active,$calls_done,$max_allowed,$group_id,$subgroup_id) = $sth->fetchrow;
my ($subj_id,$active,$calls_done,$max_allowed) = $sth->fetchrow;
$sth->finish;

# $sth = $dbh->prepare("select subj_id from lre11_subj where subgroup_id = \'$subgroup_id\'
                      # and pin <> \'$pin\'");
$sth = $dbh->prepare("SELECT lp.id 
                      FROM participants p
                      JOIN participant_links pl ON p.id = pl.participant_id
                      JOIN participants lp ON pl.linked_participant_id = lp.id
                      WHERE p.id = \'$subj_id\'");
$sth->execute;
my($ce_subj_id) = $sth->fetchrow;
$sth->finish;
if($ce_subj_id !~ /\d+/){ $ce_subj_id = '99999' } # may need to flesh this out to search for a claque


if ( !defined( $subj_id )) {
    procwrite($proc_id,"validate_resp","INVALID_PIN");
}
elsif ( !defined( $active ) or $active ne 1 ) {
    procwrite($proc_id,"validate_resp","INACTIVE_PIN");
}
elsif ( !defined( $ce_subj_id )) {
    procwrite($proc_id,"validate_resp","NOPAIR_SBJ");
}
elsif ( $calls_done >= $max_allowed ) {
    procwrite($proc_id,"validate_resp","MAX_CALLS");
}
else {
    # my $sth = $dbh->prepare( "update telco_subjects set cip='Y' where subj_id=?" );
    my $sth = $dbh->prepare("UPDATE participants
                             SET conversation_in_progress = 1
                             WHERE participants.id = ?");
    $sth->execute( $subj_id );
    $sth->finish;
    # print "$subj_id $group_id $ce_subj_id\n";
    print "$subj_id $ce_subj_id\n";

    procwrite($proc_id,"validate_resp","CFIBOK");
    procwrite($proc_id,"rec_length",900);
    
    procwrite($proc_id,"subj_id",$subj_id);
    # procwrite($proc_id,"group_id",$group_id);
    # procwrite($proc_id,"subgroup_id",$subgroup_id);
    procwrite($proc_id,"ce_subj_id",$ce_subj_id);


    # $sth = $dbh->prepare("select pin from lre11_subj where subj_id=?");
    $sth = $dbh->prepare("SELECT p.pin
                          FROM participants p
                          JOIN $lui{database}.enrollments e ON p.enrollment_id = e.id
                          WHERE p.id = ?");
    $sth->execute($ce_subj_id);
    ($ce_pin) = $sth->fetchrow;
    $sth->finish;
    procwrite($proc_id,"ce_pin",$ce_pin);


    # $sth = $dbh->prepare("select phone_number from telco_phones where subj_id=?");
    $sth = $dbh->prepare("SELECT ph.number
                          FROM participants p
                          JOIN participant_phones pph ON p.id = pph.participant_id
                          JOIN phones ph ON pph.phone_id = ph.id
                          WHERE p.id = ?");
    $sth->execute($ce_subj_id);
    my ($ce_phnum) = $sth->fetchrow;
    $sth->finish;  
    procwrite($proc_id,"ce_number",$ce_phnum) if $ce_phnum =~ /^(1|011)\d+$/;	

}

$dbh->disconnect;
