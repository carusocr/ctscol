#!d:\\perl\\bin\\perl.exe

use DBI;
use lib "d:\\fisher_v0.5\\Perl\\";
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

my $sqlqry = "insert into mx7spa_io_calls ( io_start, io_phnum, io_ani, io_line_id, io_proc_id ) 
                                            values ( NOW(), ?, ?, ?, ?)";

$sth = $dbh->prepare($sqlqry);
$sth->execute($phnum,$phnum,$line_id,$proc_id);
my $side_id = $dbh->{mysql_insertid};
$sth->finish;

foreach my $ari(qw/subj_id phone_id/){
    my $ariv = procread($proc_id,$ari);
    if($ariv != -1){
	ioc_update($dbh, $side_id, $ari, $ariv);
    }
}

($tpc_file,$tpc_id) = get_tod($dbh);

$dbh->disconnect;

my $retrn = $side_id || "DB_FAILED";

procwrite($proc_id,"topic_file",$tpc_file);
procwrite($proc_id,"topic_id",$tpc_id);
procwrite($proc_id,"newside_resp",$retrn);



