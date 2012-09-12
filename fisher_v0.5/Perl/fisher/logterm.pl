#!d:\\perl\\bin\\perl.exe

use lib "d:/fisher_v0.5/Perl/";
use DBI;

use FshPerl;
use Semfile;

my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $proc_dir = 'p:/proc';
my $proc_id = shift;
my $proc_id = sprintf("%0.2d",$proc_id);

print "OK $proc_id $proc_dir asdfadsflkadjsfklajflk\n";
die "$!\n" unless defined($proc_dir);


die "No such directory\n" unless -d "$proc_dir/$proc_id";

my $frpt = shift;


print "$frpt\n";

die "Invalid proc id $proc_id\n" unless $proc_id > 0;
unlink("$proc_dir/$proc_id/logterm_resp") if -e "$proc_dir/$proc_id/logterm_resp";

my %dtbl=();
print "$proc_dir\n";

chdir("$proc_dir/$proc_id") || die "NSD $!";

open F,"$frpt" || die "$!";
while(<F>){
    chop;
    print "$_\n";
    my ($k,$v)=split /\=/,$_;
    next if $v == -1;
    $dtbl{$k} = $v;
}
close(F);

if(-e "subj_id"){
    $dtbl{SUBJ_ID} = $dtbl{CRA_SUBJID} = procread($proc_id,"subj_id");    
}

if(-e "side_id"){
    $dtbl{SIDE_ID} = $dtbl{CRA_SIDEID} = procread($proc_id,"side_id");
}

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

if(exists($dtbl{CRA_SIDEID})){
    my $sqlcmd = "update mx7spa_io_calls set io_end=NOW(), io_hup_status='$dtbl{TERMSTAT}', io_length = NOW() - io_start where side_id='$dtbl{CRA_SIDEID}'";
    my $sth = $dbh->prepare($sqlcmd);
    $sth->execute;
    $sth->finish;
}
if(exists($dtbl{CRB_SIDEID})){

    $sqlcmd = "update mx7spa_io_calls set io_end=NOW(), io_hup_status='$dtbl{TERMSTAT}', io_length = NOW() - io_start where side_id='$dtbl{CRB_SIDEID}'";
    my $sth = $dbh->prepare($sqlcmd);
    $sth->execute;
    $sth->finish;

}

if(exists($dtbl{FILA})){ $dtbl{FILA} =~ s/^\w\:.*\\// }
if(exists($dtbl{FILB})){ $dtbl{FILB} =~ s/^\w\:.*\\// }

$sutval = "18:00";

#if($dtbl{TERMSTAT} =~ /FULLREC/){
#    $sutval = "18:00";
#}
#else{
#    $sutval = "12:00";
#}

if (exists($dtbl{SUBJ_ID})){
    
    $sth = $dbh->prepare( "update telco_subjects set cip='N',sut = date_add(now(), interval '$sutval' HOUR_MINUTE) where subj_id=?" );
    $sth->execute( $dtbl{SUBJ_ID} );
    $sth->finish;

    $sth = $dbh->prepare( "delete from mx7spa_exclude where subj_id=?" );
    $sth->execute( $dtbl{SUBJ_ID} );
    $sth->finish;

}
else {
    print "$dtbl{SUBJ_ID} not defined\nFailed to update telco_subjects\n";
}


if (exists($dtbl{CE_SUBJ_ID})) {
    $sth = $dbh->prepare( "update telco_subjects set cip='N',sut = date_add(now(), interval '$sutval' HOUR_MINUTE) where subj_id=?" );
    $sth->execute( $dtbl{CE_SUBJ_ID} );
    $sth->finish;

    $sth = $dbh->prepare( "delete from mx7spa_exclude where subj_id=?" );
    $sth->execute( $dtbl{SUBJ_ID} );
    $sth->finish;

}

if (exists($dtbl{CALL_ID})) {

    $sth = $dbh->prepare( "update mx7spa_br_calls set 
                                  filesiza='$dtbl{FILESIZA}', 
                                  filesizb=$dtbl{FILESIZB}, 
                                  hup_status='$dtbl{TERMSTAT}', 
                                  fila='$dtbl{FILA}', 
                                  filb='$dtbl{FILB}', 
                                  runtime='$dtbl{RUNTIME}', 
                                  topic_id='$dtbl{TOPIC_ID}' 
                           where call_id='$dtbl{CALL_ID}'" );
    $sth->execute;
    $sth->finish;

    if($dtbl{TERMSTAT} =~ /FULLREC/){
	$sth = $dbh->prepare("update mx7spa_subj set calls_done = calls_done + 1 where subj_id=?");
	$sth->execute( $dtbl{SUBJ_ID} );
	$sth->finish;

	$sth = $dbh->prepare("insert into mx7spa_subj_pairs (subj_id,spoke_to,call_id) values (?,?,?)");
	$sth->execute($dtbl{CALL_ID},$dtbl{SUBJ_ID},$dtbl{CE_SUBJ_ID});
	$sth->finish;
    }
}
$dbh->disconnect;
