#!c:/perl/bin/perl.exe

use DBI;

use lib "../";
use FshPerl;
use Semfile;
my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $subj_id = shift;
my $ce_subj_id = shift;
my $cra_side_id = shift;
my $crb_side_id = shift;
my $pid = sprintf("%0.2d",shift);

die "Invalid procid $pid\n" unless procvalid($pid);

##my $topic_id = procread($pid,"topic_id");

my $dbh = get_dbh();

my $sth = $dbh->prepare( "insert into sre12_br_calls ( cra_side_id, crb_side_id, call_date ) values ( ?, ?, NOW() )" );

$sth->execute($cra_side_id, $crb_side_id );
my $br_call_id = $dbh->{mysql_insertid};
$sth->finish;

##$gclock->release;

$sth = $dbh->prepare( "update sre12_io_calls set subj_id=?, bridged_to=?, br_call_id=? where side_id=?" );
$sth->execute( $subj_id, $crb_side_id, $br_call_id, $cra_side_id );
$sth->execute( $ce_subj_id, $cra_side_id, $br_call_id, $crb_side_id );
$sth->finish;

$sth = $dbh->prepare("delete from sre12_exclude where subj_id=?");
$sth->execute( $subj_id );
$sth->execute( $ce_subj_id );
$sth->finish;

rel_dbh($dbh);

my $retrn = $br_call_id || "DB_FAILED";

procwrite($pid,'logbridge_resp',$retrn);

