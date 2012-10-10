#!/usr/bin/perl

use lib "c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl";
use FshPerl;
use DBI;

my %call_ct = ();

my $dbh = get_dbh();

my $sth = $dbh->prepare("select subj_id,IFNULL(calls_done,0) from sre12_subj");
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
    sre12_br_calls mbc, 
    sre12_io_calls micA, 
    sre12_io_calls micB
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
	$sth = $dbh->prepare("update sre12_subj set calls_done = $call_ct{$_}{BR_CALLS} where subj_id = $_");
	$sth->execute;
	$sth->finish;
	print "$_ $call_ct{$_}{SUBJ} $call_ct{$_}{BR_CALLS}\n";
    }
}


rel_dbh($dbh);

