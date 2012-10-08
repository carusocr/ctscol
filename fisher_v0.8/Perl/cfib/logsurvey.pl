#!d:\\perl\\bin\\perl.exe

use DBI;
use lib "d:\\fisher_v0.8\\Perl\\";
use FshPerl;

$call_id=shift;
$field=shift;
$value=shift;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || die "Cannot connect to server\n";
my $sth = $dbh->prepare("update lre11_br_calls set $field = \'$value\' where call_id = \'$call_id\'");
$sth->execute;
$sth->finish;
$dbh->disconnect;




