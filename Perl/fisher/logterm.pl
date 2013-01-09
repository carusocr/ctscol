#!c:/perl/bin/perl.exe
use strict;
use DBI;

use lib "../";
use FshPerl;
use Semfile;
my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $proc_id = sprintf("%0.2d",shift);
my $frpt = shift;
die "Invalid proc id $proc_id\n" unless procvalid($proc_id);

unlink("$proc_dir/$proc_id/logterm_resp") if -e "$proc_dir/$proc_id/logterm_resp";
chdir("$proc_dir/$proc_id") || die "Could not change to $proc_dir/$proc_id\n";

my %dtbl=();
FshPerl::init_dtbl(\%dtbl);
FshPerl::load_dtbl($proc_id, $frpt, \%dtbl);

my $dbh    = get_dbh();
my $sth    = undef;
my $sqlcmd = undef;

$sqlcmd = 'update sre12_io_calls set io_end=NOW(), io_hup_status=?, io_length = NOW() - io_start where side_id=?';
$sth    = $dbh->prepare($sqlcmd);

foreach my $side_id(qw/CRA_SIDEID CRB_SIDEID/){
    print $dtbl{$side_id} ."\n";
    if(exists($dtbl{$side_id})){
	$sth->execute($dtbl{TERMSTAT},$dtbl{$side_id});
    }
}
$sth->finish;

$sqlcmd = 'update telco_subjects set cip=? ,sut = date_add(now(), interval ? HOUR_MINUTE) where subj_id=?';
$sth    = $dbh->prepare($sqlcmd);
foreach my $subj_id(qw/CRA_SUBJID CRB_SUBJID/){
    if(exists($dtbl{$subj_id})){
	$sth->execute($dtbl{CIP},$dtbl{SUTVAL},$dtbl{$subj_id} );	
    }
}
$sth->finish;

$sqlcmd = 'delete from sre12_exclude where subj_id = ?';
$sth = $dbh->prepare($sqlcmd);
foreach my $subj_id(qw/CRA_SUBJID CRB_SUBJID/){
    if(exists($dtbl{$subj_id})){
	$sth->execute($dtbl{$subj_id});	
    }
}
$sth->finish;

if (exists($dtbl{CALL_ID})) {

    $sth = $dbh->prepare("update sre12_br_calls set filesiza=?, filesizb=?, hup_status=?,
                                  fila=?, filb=?, runtime=?, topic_id=?, fila_md5=?, filb_md5=? where call_id=? ");
    $sth->execute($dtbl{FILESIZA},
		  $dtbl{FILESIZB},
		  $dtbl{TERMSTAT},
		  $dtbl{FILA_NAME},
		  $dtbl{FILB_NAME},
		  $dtbl{RUNTIME},
		  $dtbl{TOPIC_ID},
		  $dtbl{FILA_MD5},
		  $dtbl{FILB_MD5},
		  $dtbl{CALL_ID});      
    $sth->finish;

    if($dtbl{TERMSTAT} =~ /FULLREC/){
	print "fullrec\n";

	load_callct($dbh,$proc_id,\%dtbl);

	print "postcallct\n";

	my $sth = $dbh->prepare("update sre12_subj set calls_done = ? where subj_id=?");
	foreach my $idf(qw/CRA_SUBJID CRB_SUBJID/){
	    $sth->execute($dtbl{ $idf . '_CALLCT' }, $dtbl{ $idf } );
	}
	$sth->finish;

	printf "%s\t%s\t%s\n",$dtbl{CRA_SUBJID},$dtbl{CRB_SUBJID},$dtbl{CALL_ID};

	$sth = $dbh->prepare('insert into sre12_subj_pairs (subj_id, spoke_to, call_id) values ( ?, ?, ?)');
	$sth->execute($dtbl{CRA_SUBJID},$dtbl{CRB_SUBJID},$dtbl{CALL_ID});
	$sth->finish;

    }
}

rel_dbh($dbh);

