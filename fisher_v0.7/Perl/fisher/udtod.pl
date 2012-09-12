#!c:/Perl/bin/perl.exe

use DBI;

use lib "../";
use FshPerl;

my $dbh = get_dbh();

#$s = $dbh->prepare("select topic_id from sre12_topics where tod_yn = 'Y'");
#$s->execute;
#($yest_tod) = $s->fetchrow;
#$s->finish;
#if($yest_tod){
#    print "YEST: $yest_tod\n";
#}
#else{
#    print "No prior topic\n";
#}
#for(;;){
#    $newtod = int(rand(42)) + 1;
#    if(! $yest_tod){ last }
#    elsif($newtod != $yest_tod){ last }
#    else{ print "try again\n" }
#}

$s = $dbh->prepare("select greatest(mod(date_format(now(),'%j'),45),1)");
$s->execute;
($newtod) = $s->fetchrow;
$s->finish;

if($newtod == 2 || $newtod == 16){
    $newtod += int(rand(3)) + 8;
}

print "NEW: $newtod\n";

$s = $dbh->prepare("update sre12_topics set tod_yn = 'N'");
$s->execute;
$s->finish;

$s = $dbh->prepare("update sre12_topics set tod_yn = 'Y', topic_date = now() where topic_id = '$newtod'");
$s->execute;
$s->finish;

rel_dbh($dbh);










