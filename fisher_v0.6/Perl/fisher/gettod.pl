#!c:\\perl\\bin\\perl.exe

use DBI;

use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;
use Semfile;

$procid = sprintf("%0.2d",shift);

$cmd = "select summ_file,topic_file from sre12_topics where tod_yn = 'Y'";

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $sth = $dbh->prepare("$cmd");
$sth->execute;
($summ,$topic) = $sth->fetchrow;
$sth->finish;
$dbh->disconnect;

procwrite($procid,"topic.txt",$topic);
procwrite($procid,"topic_summ.txt",$summ);



