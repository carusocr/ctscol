#!c:/perl/bin/perl.exe

use DBI;

use lib "c:/fisher_v0.8/Perl/";
# use lib "c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl/";
use FshPerl;
use Semfile;
my %timearry = ();

@{ $timearry{'init'} } = (localtime)[0,1,2,3];

my $proc_id = sprintf("%0.2d",shift);
my $frpt = shift; # frpt ~ "final report"
die "Invalid proc id $proc_id\n" unless $proc_id > 0;
unlink("$proc_dir/$proc_id/logterm_resp") if -e "$proc_dir/$proc_id/logterm_resp";

my %dtbl=();
chdir("$proc_dir/$proc_id");
open F,"$frpt" || die "$!";
while(<F>){
    chop;
    my ($k,$v)=split /\=/,$_;
    $dtbl{$k} = $v;
}
close(F);

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

if($dtbl{FILA}){ $dtbl{FILA} =~ s/^\w\:.*\\// }
if($dtbl{FILB}){ $dtbl{FILB} =~ s/^\w\:.*\\// }

# my $sth = $dbh->prepare( "update lre11_io_calls set io_end=NOW(), io_hup_status=?, io_length = NOW() - io_start where side_id=?" );
my $sth = $dbh->prepare("UPDATE channels ch
                         SET ch.ended_at = NOW(), ch.termination_status = ?, ch.file_size_in_bytes = ?, ch.file_name = ?, ch.updated_at = NOW()
                         WHERE ch.id = ?");
# $sth->execute( $dtbl{TERMSTAT}, $dtbl{SIDE_ID} );
# $sth->execute( $dtbl{TERMSTAT}, $dtbl{CE_SIDE_ID} );
$sth->execute( $dtbl{TERMSTAT}, $dtbl{FILASIZE}, $dtbl{FILA}, $dtbl{SIDE_ID});
$sth->execute( $dtbl{TERMSTAT}, $dtbl{FILBSIZE}, $dtbl{FILB}, $dtbl{CE_SIDE_ID});
$sth->finish;


if ( $dtbl{SUBJ_ID} ) {
    # $sth = $dbh->prepare( "update telco_subjects set cip='N' where subj_id=?" );
    $sth = $dbh->prepare("UPDATE participants p
                          SET p.conversation_in_progress = 0, p.updated_at = NOW()
                          WHERE p.id = ?");
    $sth->execute( $dtbl{SUBJ_ID} );
    $sth->finish;
}

if ( $dtbl{CE_SUBJ_ID} ) {
    # $sth = $dbh->prepare( "update telco_subjects set cip='N' where subj_id=?" );
    $sth = $dbh->prepare("UPDATE participants p
                          SET p.conversation_in_progress = 0, p.updated_at = NOW()
                          WHERE p.id = ?");
    $sth->execute( $dtbl{CE_SUBJ_ID} );
    $sth->finish;
}
if ( $dtbl{CALL_ID} ) {
    # $sth = $dbh->prepare( "update lre11_br_calls set filesiza=?, filesizb=?,
                           # hup_status=?, fila=?, filb=?, runtime=?, topic_id=? where call_id=?" );
    
    $sth = $dbh->prepare("UPDATE conversations c
                          SET c.ended_at = NOW(), c.topic_id = ?, c.updated_at = NOW()
                          WHERE c.id = ?");
    # $sth->execute( $dtbl{FILASIZE}, $dtbl{FILBSIZE}, $dtbl{TERMSTAT}, 
                   # $dtbl{FILA}, $dtbl{FILB}, $dtbl{RUNTIME}, $dtbl{TOPIC_ID}, $dtbl{CALL_ID});
    $sth->execute( $dtbl{RUNTIME}, $dtbl{TOPIC_ID}, $dtbl{CALL_ID});
    $sth->finish;

    # if($dtbl{TERMSTAT} =~ /FULLREC/){
    #     $sth = $dbh->prepare("update lre11_subj set calls_done = calls_done + 1 where subj_id=?");
    #     $sth->execute( $dtbl{SUBJ_ID} );
    #     $sth->execute( $dtbl{CE_SUBJ_ID} );
    #     $sth->finish;
    # }
    
}
$dbh->disconnect;


