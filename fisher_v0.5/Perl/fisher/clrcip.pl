#!c:\\Perl\\bin\\perl.exe

use DBI;
use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;
my $dbh = DBI->connect($telco_mysql{dbistr},
                       $telco_mysql{userid},
                       $telco_mysql{passwd}) || die "Cannot connect to server\n";

my $s = $dbh->prepare("select subj_id from mx7spa_subj");
$s->execute;
while(my ($sid) = $s->fetchrow){ push(@sids,$sid) }
$s->finish;

for(@sids){
    my $sth = $dbh->prepare("update telco_subjects ts set cip = 'N' where cip = 'Y' and subj_id = '$_'");
    $sth->execute;
    $sth->finish;
}
$dbh->disconnect;



