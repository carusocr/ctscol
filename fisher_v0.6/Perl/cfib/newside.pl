#!c:/perl/bin/perl.exe

use DBI;
use lib "d:/fisher_v0.6/Perl/";
use FshPerl;
use Semfile;

my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $phnum = shift;
my $line_id = sprintf("%0.2d",shift);
my $proc_id = sprintf("%0.2d",shift);

unlink("$proc_dir/$proc_id/newside_resp") if -e "$proc_dir/$proc_id/newside_resp";

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

## serialize side_id requests

my $gclock = Semfile->new("$proc_dir/gc_lock");

my $sth = $dbh->prepare( "insert into rats_io_calls ( io_start, io_ani, io_proc_id, io_line_id ) 
                                            values ( NOW(),    $phnum, $proc_id,   $line_id)" );

$sth->execute;
my $side_id = $dbh->{mysql_insertid};
$sth->finish;

$gclock->release;

## end serialize side_id requests

$sth = $dbh->prepare( "select topic_id,topic_file from rats_topics where tod_yn = 'Y'" );
$sth->execute;
($tpc_id,$tpc_file) = $sth->fetchrow;
$sth->finish;
$dbh->disconnect;

my $retrn = $side_id || "DB_FAILED";

procwrite($proc_id,"topic_file",$tpc_file);
procwrite($proc_id,"topic_id",$tpc_id);
procwrite($proc_id,"newside_resp",$retrn);



