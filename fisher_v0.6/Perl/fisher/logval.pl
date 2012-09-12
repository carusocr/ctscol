#!d:\\perl\\bin\\perl.exe

use DBI;
use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;

$side_id=shift;
$value=shift;
$dbfield=shift;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || die "Cannot connect to server\n";
my $sth = $dbh->prepare("update sre12_io_calls set $dbfield = \'$value\',io_end = now() where side_id = \'$side_id\'");
$sth->execute;
$sth->finish;
$dbh->disconnect;




