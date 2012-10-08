#!c:/perl/bin/perl.exe

use DBI;
use lib "../";
use FshPerl;
use Semfile;

my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $phnum = shift;
my $line_id = sprintf("%0.2d",shift);
my $proc_id = sprintf("%0.2d",shift);

print "$phnum $line_id $proc_id\n";
unlink("$proc_dir/$proc_id/newside_resp") if -e "$proc_dir/$proc_id/newside_resp";

my $dbh = get_dbh();

## serialize side_id requests
# disabled because of locking race condition problem KMW 20051219
##my $gclock = Semfile->new("$proc_dir/gc_lock");

my $sth = $dbh->prepare( "insert into sre12_io_calls ( io_start, io_ani, io_proc_id, io_line_id ) 
                                            values ( NOW(),    $phnum, $proc_id,   $line_id)" );

$sth->execute;
my $side_id = $dbh->{mysql_insertid};
$sth->finish;
print "$side_id\n";
##$gclock->release;

## end serialize side_id requests

$sth = $dbh->prepare( "select topic_id,topic_file from sre12_topics where tod_yn = 'Y'" );
$sth->execute;
($tpc_id,$tpc_file) = $sth->fetchrow;
$sth->finish;

rel_dbh($dbh);

my $retrn = $side_id || "DB_FAILED";

procwrite($proc_id,"topic_file",$tpc_file);
procwrite($proc_id,"topic_id",$tpc_id);
procwrite($proc_id,"newside_resp",$retrn);



