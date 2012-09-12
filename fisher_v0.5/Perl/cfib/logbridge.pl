#!d:\\perl\\bin\\perl.exe

use DBI;

use lib "d:\\fisher_v0.5\\Perl\\";
use FshPerl;
use Semfile;
my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $subj_id = shift;
my $ce_subj_id = shift;
my $cra_side_id = shift;
my $crb_side_id = shift;
my $pid = sprintf("%0.2d",shift);

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $sth = $dbh->prepare( "insert into lre11_br_calls ( cra_side_id, crb_side_id, call_date )
                          values ('$cra_side_id','$crb_side_id',NOW())" );

my $gclock = Semfile->new("$proc_dir/gc_lock");

$sth->execute;
my $br_call_id = $dbh->{mysql_insertid};
$sth->finish;

$gclock->release;

$sth = $dbh->prepare( "update lre11_io_calls set subj_id=?, bridged_to=?, br_call_id=? where side_id=?" );
$sth->execute( $subj_id, $crb_side_id, $br_call_id, $cra_side_id );
$sth->execute( $ce_subj_id, $cra_side_id, $br_call_id, $crb_side_id );
$sth->finish;

$dbh->disconnect;
my $retrn = $br_call_id || "DB_FAILED";
open F,">$proc_dir/$pid/logbridge_resp" || die "$!";
print F "$retrn\n";
close(F);
