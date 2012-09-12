#!c:/perl/bin/perl.exe

use DBI;

use lib "../";
use FshPerl;
use Semfile;

$procid = sprintf("%0.2d",shift);

$cmd = "select summ_file,topic_file from sre12_topics where tod_yn = 'Y'";

my $dbh = get_dbh();

my $sth = $dbh->prepare("$cmd");
$sth->execute;
($summ,$topic) = $sth->fetchrow;
$sth->finish;

rel_dbh($dbh);

procwrite($procid,"topic.txt",$topic);
procwrite($procid,"topic_summ.txt",$summ);



