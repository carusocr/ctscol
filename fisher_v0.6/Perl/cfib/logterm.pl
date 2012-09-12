#!c:/perl/bin/perl.exe

use DBI;
use Getopt::Std;
use File::Slurp;
use lib "d:/fisher_v0.6/Perl/";
use lib "c:/cygwin/home/ctscoll/fisher_v0.6/Perl/";
use FshPerl;
use Data::Dumper;
use Archive::Tar;
use Digest::MD5::File qw(file_md5_hex);

getopt('p:',\%opts);
my $proc_id = sprintf("%0.2d", $opts{p});
my $proc_dir = "$proc_dir/$proc_id";

die "No such dir $proc_id\n" unless -d $proc_dir;
chdir($proc_dir) || die "$!";

my ($ss,$mi,$hr,$dy,$mt,$yr) = (localtime)[0,1,2,3,4,5];
my $tar_fil = sprintf("%0.4d%0.2d%0.2d_%0.2d%0.2d%0.2d.tgz",
		      $yr + 1900,$mt + 1,$dy,$hr,$mi,$ss);

my %dtbl=();
load_dtbl(\%dtbl, $tar_fil);

print Dumper(%dtbl);

my $dbh = DBI->connect($telco_mysql{dbistr},
		       $telco_mysql{userid},
		       $telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my $sth = $dbh->prepare('update rats_io_calls set io_end=NOW(), io_hup_status=?, io_length = NOW() - io_start where side_id=?');

if(defined($dtbl{SIDE_ID})){ $sth->execute( $dtbl{TERMSTAT}, $dtbl{SIDE_ID} ) }
if(defined($dtbl{CE_SIDE_ID})){ $sth->execute( $dtbl{TERMSTAT}, $dtbl{CE_SIDE_ID} ) }
$sth->finish;

$sth = $dbh->prepare( "update telco_subjects set cip='N' where subj_id=?" );

foreach my $sidstr(qw/SUBJ_ID CE_SUBJ_ID/){
    if ( $dtbl{$sidstr} ) {
	$sth->execute( $dtbl{$sidstr} );
    }
}
$sth->finish;

if ( $dtbl{CALL_ID} ) {
    $sth = $dbh->prepare( "update rats_br_calls set ".
			  "filesiza=?,   filesizb=?,".
			  "fila=?,       filb=?,    ".
			  "ulmd5a=?,     ulmd5B=?   ".
			  "hup_status=?, cpgend=?, cplang=?,".
			  "cr_pin=?,     ce_pin=?, ce_pin_confirm=?,".
			  "runtime=?,    topic_id=? ".
			  "where call_id=?" );
    $sth->execute( $dtbl{FNAMA_SIZE}, $dtbl{FNAMB_SIZE}, 
		   $dtbl{FNAMA_STEM}, $dtbl{FNAMB_STEM},
                   $dtbl{FNAMA_MD5},  $dtbl{FNAMB_MD5},
		   $dtbl{TERMSTAT},   $dtbl{CE_GEND},    $dtbl{GROUP_ID},
		   $dtbl{CR_PIN},     $dtbl{CE_PIN},     $dtbl{CEPIN_CONFIRM},
		   $dtbl{RUNTIME},    $dtbl{TOPIC_ID},   $dtbl{CALL_ID});
    $sth->finish;
    if($dtbl{TERMSTAT} =~ /FULLREC/){
	$sth = $dbh->prepare("update rats_subj set calls_done = calls_done + 1 where subj_id=?");
	$sth->execute( $dtbl{SUBJ_ID} );
	$sth->execute( $dtbl{CE_SUBJ_ID} );
	$sth->finish;
    }   
}

$dbh->disconnect;

sub load_dtbl {
    my ($hash_ref, $tf) = @_;

    opendir PD,"." || die "$!";
    my @meta_files = grep { -f && !/.*\..*/ && !/final_report/ } readdir PD;
    closedir PD;

    $tf_obj = Archive::Tar->new();
    $tf_obj->add_files(@meta_files);
    $tf_obj->write($tf, COMPRESS_GZIP);

    $hash_ref->{TARFILE} = $tf;

    while(my $nf = shift(@meta_files)){
	my ($nv) = read_file($nf, chomp => 1);
	$nv =~ s/\s+$//;
	$hash_ref->{ uc($nf) } = $nv;
    }
    foreach my $fstr(qw/FNAMA FNAMB/){
	if( -f $hash_ref->{$fstr} ){
	    $hash_ref->{ $fstr . "_SIZE" } = -s $hash_ref->{$fstr}; 
	    $hash_ref->{ $fstr . "_MD5" } = file_md5_hex($hash_ref->{$fstr});
	    ( $hash_ref->{ $fstr . "_STEM" } ) = $hash_ref->{$fstr} =~ /([^\\\/]+)$/; 
	}
    }
}


