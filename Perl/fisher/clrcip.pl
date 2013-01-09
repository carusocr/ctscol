#!c:/Perl/bin/perl.exe

use DBI;
use lib "../";
use FshPerl;
use Semfile;
my $dbh = get_dbh();

my $s = $dbh->prepare("select subj_id from sre12_subj");
$s->execute;
while(my ($sid) = $s->fetchrow){ push(@sids,$sid) }
$s->finish;

for(@sids){
    my $sth = $dbh->prepare("update telco_subjects ts set cip = 'N' where cip = 'Y' and subj_id = '$_'");
    $sth->execute;
    $sth->finish;
}

rel_dbh($dbh);



