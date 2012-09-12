#!d:\\perl\\bin\\perl.exe

use DBI;

use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;
use Semfile;
my %timearry = ();
my %rej_subjid = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $proc_id = sprintf("%0.2d",shift);
my $pin = shift;
my $phnum = shift;

die "Invalid proc id $proc_id\n" unless $proc_id > 0;

unlink("$proc_dir/$proc_id/validate_resp") if -e "$proc_dir/$proc_id/validate_resp";

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $sth = $dbh->prepare("
select 
    micA.subj_id,
    micB.subj_id,
    sec_to_time(unix_timestamp(now()) - unix_timestamp(mbc.call_date)),
    mbc.call_date,
    msA.active,
    msB.active
from 
    sre12_br_calls mbc, 
    sre12_io_calls micA, 
    sre12_io_calls micB,
    sre12_subj msA,
    sre12_subj msB
where 
    mbc.hup_status  = 'FULLREC'    and 
    mbc.cra_side_id = micA.side_id and 
    mbc.crb_side_id = micB.side_id and
    msA.subj_id = micA.subj_id     and
    msB.subj_id = micB.subj_id     and 
    unix_timestamp(now()) - unix_timestamp(mbc.call_date) < 57600
");

$sth->execute;
while(my ($subjA,$subjB,$hrs,$prevcd,$activeA,$activeB) = $sth->fetchrow){
    ++$rej_subjid{$subjA} unless $activeA =~ /^T$/;
    ++$rej_subjid{$subjB} unless $activeB =~ /^T$/;
}
$sth->finish;

$sth = $dbh->prepare( "select subj_id, active, calls_done, max_allowed, group_id 
                          from sre12_subj where pin=\'$pin\'");

$sth->execute;
my ($subj_id,$active,$calls_done,$max_allowed,$group_id) = $sth->fetchrow;
$sth->finish;

if ( !defined( $subj_id )) {
    procwrite($proc_id,"validate_resp","NSPIN");
}
elsif ( !defined( $active ) ) {
    procwrite($proc_id,"validate_resp","NACTIVE");
}
elsif (exists($rej_subjid{$subj_id})){
    procwrite($proc_id,"validate_resp","CMOVER");
}
elsif ( $active eq 'L' ) {
    procwrite($proc_id,"validate_resp","LNGDAYREJ");
}
elsif ( $calls_done >= $max_allowed ) {
    procwrite($proc_id,"validate_resp","CMOVER");
}
elsif ( $active !~ /^[YT]$/ ) {
    procwrite($proc_id,"validate_resp","NACTIVE");
}
else {
    my $sth = $dbh->prepare( "update telco_subjects set cip='Y',sut = date_add(now(),interval '01:00' HOUR_MINUTE) where subj_id=?" );
    $sth->execute( $subj_id );
    $sth->finish;
    print "$subj_id $group_id\n";

    procwrite($proc_id,"validate_resp","FSHIBOK");
    procwrite($proc_id,"validate_resp","NONE");

    procwrite($proc_id,"rec_length",1000);
    procwrite($proc_id,"subj_id",$subj_id);
    procwrite($proc_id,"group_id",$group_id);

}

$dbh->disconnect;
