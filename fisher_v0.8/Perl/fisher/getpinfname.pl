#!c:/perl/bin/perl.exe

use DBI;
use lib "../";
use FshPerl;
use Semfile;

$procid = sprintf("%0.2d",shift);
$pin = shift;

my $dbh = get_dbh();

$sql = "select ts.fname from telco_subjects ts, sre12_subj fs where fs.pin = ? and ts.subj_id = fs.subj_id";
print "$sql\n";
$sth = $dbh->prepare($sql);
$sth->execute($pin);
($fname) = $sth->fetchrow;
$sth->finish;

rel_dbh($dbh);

procwrite($procid,"getpinfname_resp.txt",$fname);
procwrite($procid,"fname",$fname);


