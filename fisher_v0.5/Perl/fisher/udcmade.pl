#!/usr/bin/perl
exit;
use DBI;

my $server = 'thalia2.ldc.upenn.edu';
my $db = 'telco_master';
my $username = 'walkerk';
my $pwd = '________';
my $tstamp = localtime(time);
my %call_ct = ();

my $dbh = DBI->connect("dbi:mysql:$db:$server",$username,$pwd);

my $sth = $dbh->prepare("select subj_id,IFNULL(calls_done,0) from mx7spa_subj");
$sth->execute;
while(my ($subj_id,$calls_done) = $sth->fetchrow){
    $call_ct{$subj_id}{SUBJ}     = $calls_done;
    $call_ct{$subj_id}{BR_CALLS} = 0;
}
$sth->finish;

my $qry = "

select 
    micA.subj_id,
    micB.subj_id
from 
    mx7spa_br_calls mbc, 
    mx7spa_io_calls micA, 
    mx7spa_io_calls micB
where 
    mbc.hup_status  = 'FULLREC'    and 
    mbc.cra_side_id = micA.side_id and 
    mbc.crb_side_id = micB.side_id 
";

$sth = $dbh->prepare($qry);
$sth->execute;

while(my ($sa,$sb) = $sth->fetchrow){
    ++$call_ct{$sa}{BR_CALLS};
    ++$call_ct{$sb}{BR_CALLS};
}
$sth->finish;

for(sort keys %call_ct){
    if($call_ct{$_}{SUBJ} != $call_ct{$_}{BR_CALLS}){
	$sth = $dbh->prepare("update mx7spa_subj set calls_done = $call_ct{$_}{BR_CALLS} where subj_id = $_");
	$sth->execute;
	$sth->finish;
	print "$_ $call_ct{$_}{SUBJ} $call_ct{$_}{BR_CALLS}\n";
    }
}


$dbh->disconnect;

