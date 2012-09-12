#!c:\\perl\\bin\\perl.exe

use DBI;
use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;

$procid = sprintf("%0.2d",shift);
$pin = shift;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

$sql = "select ts.fname from telco_subjects ts, mx7spa_subj fs where fs.pin = ? and ts.subj_id = fs.subj_id";
print "$sql\n";
$sth = $dbh->prepare($sql);
$sth->execute($pin);
($fname) = $sth->fetchrow;
$sth->finish;
$dbh->disconnect;

procwrite($procid,"getpinfname_resp.txt",$fname);
procwrite($procid,"fname",$fname);


