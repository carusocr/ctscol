#!C:\\Perl\\bin\\perl.exe

use DBI;

use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;
use Semfile;

my @side_id_lst = ();

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $qry = "
select 
    mbc.cra_side_id,
    mbc.crb_side_id
from 
    sre12_br_calls mbc, 
    sre12_io_calls micA, 
    sre12_io_calls micB 
where 
    mbc.hup_status  = 'FULLREC'    and
    mbc.cra_side_id = micA.side_id and
    mbc.crb_side_id = micB.side_id and
    (micA.io_hup_status <> 'FULLREC' or
     micB.io_hup_status <> 'FULLREC')
order by mbc.call_id";

$s = $dbh->prepare($qry);
$s->execute;

while(my ($a,$b) = $s->fetchrow){
    push(@side_id_lst,$a);
    push(@side_id_lst,$b);
}
$s->finish;


my $updt_stmt = "update sre12_io_calls set io_hup_status = 'FULLREC' where side_id = ? and io_hup_status <> 'FULLREC'";

for(my $i = 0;$i < scalar(@side_id_lst);++$i){
    printf "%d\n",$side_id_lst[$i];
    my $s = $dbh->prepare($updt_stmt);
    $s->execute($side_id_lst[$i]);
    $s->finish;
}

$dbh->disconnect;








