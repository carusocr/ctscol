#!c:/perl/bin/perl.exe

use DBI;
use lib "../";
use FshPerl;

$side_id=shift;
$value=shift;
$dbfield=shift;

my $dbh = get_dbh();
my $sth = $dbh->prepare("update sre12_io_calls set $dbfield = ? ,io_end = now() where side_id = ?");
$sth->execute($value,$side_id);
$sth->finish;

rel_dbh($dbh);






