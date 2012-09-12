#!c:\\Perl\\bin\\perl.exe

use DBI;

use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;
use Semfile;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

$s = $dbh->prepare("select ms.subj_id,IFNULL(ts.gender,'X'),IFNULL(ts.state,'ZZ') from sre12_subj ms, telco_subjects ts
where ms.subj_id = ts.subj_id

");
$s->execute;
my %tbl = ();
while(my ($subj_id,$gender,$state) = $s->fetchrow){
    push(@{ $tbl{$gender}{$state} },$subj_id);
}
$s->finish;



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

#print "NEW: $newtod\n";

#$s = $dbh->prepare("update sre12_topics set tod_yn = 'N'");
#$s->execute;
#$s->finish;

#$s = $dbh->prepare("update sre12_topics set tod_yn = 'Y' where topic_id = '$newtod'");
#$s->execute;
#$s->finish;

$dbh->disconnect;








