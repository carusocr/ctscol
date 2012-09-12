#!c:\\perl\\bin\\perl.exe

use DBI;

use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;

sub emerlog {
    my $msg = shift;
    #open LOG,">>c:foo$$\.txt" || die "$!";
    #print LOG "$msg $$ \n";
    #close LOG;
}

my $procid = shift;
$procid = sprintf("%0.2d", $procid); 

emerlog("procid");


procwrite($procid,"getcallee_resp.txt","XXXX\|XXXXXXXXXX\n");

emerlog("datetime");

my ($s,$mi,$h,$d,$m,$y,$dow) = (localtime)[0,1,2,3,4,5,6];
my $dstr = (qw/Su Mo Tu We Th Fr Sa/)[$dow];
my $timecond = sprintf("%%%s%%%0.2d%%",$dstr,$h);

my $dbh = DBI->connect($telco_mysql{dbistr},
		       $telco_mysql{userid},
		       $telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";
my $sth = undef;

emerlog("dblogin");

my %sidtbl = ();

{



    local $/ = undef;
    my $tdyrec_qry   = "d:\\fisher_v0.5\\Perl\\fisher\\tdyrecs.sql";




    open F,"$tdyrec_qry" || die "$!";

    emerlog("tdyrec");
    $tdyrec_cmd = <F>;
    close(F);



    $sth = $dbh->prepare("$tdyrec_cmd");
    $sth->execute;
    while((my $sida, my $sidb) = $sth->fetchrow){
	++$sidtbl{$sida};
	++$sidtbl{$sidb};
    }
    $sth->finish;
}

my $sidstr = join(",",keys %sidtbl);

my $fullpool_qry = "d:\\fisher_v0.5\\Perl\\fisher\\getcallee.sql";
my $ldcpool_qry  = "d:\\fisher_v0.5\\Perl\\fisher\\getcleldc.sql";
my $qry          = $fullpool_qry;

emerlog("Using $qry");

my $sqlcmd = undef;

{
    emerlog("in local block");
    local $/ = undef;
    open F,"$qry" || emerlog($!);
    $sqlcmd = <F>;
    close(F);

}

$sqlcmd =~ s/AVSTRINGREPL/$timecond/;
$sqlcmd =~ s/SIDRECTDYREPL/$sidstr/;


emerlog("about to lock");
my $gclock = Semfile->new("$proc_dir/gc_lock");
emerlog("Locked $gclock");

$sth = $dbh->prepare("$sqlcmd");
emerlog("prepared");
$sth->execute;
emerlog("executed");
($subj_id,$pin,$phone_id,$number,$group_id) = $sth->fetchrow;
$sth->finish;
emerlog("SID $subj_id");
$sth = $dbh->prepare("update telco_subjects set CIP = 'Y' where subj_id = '$subj_id'");
$sth->execute;
$sth->finish;
$gclock->release;

emerlog("Returning $subj_id,$pin,$phone_id,$number,$group_id");

$sth = $dbh->prepare("delete from sre12_exclude where subj_id = '$subj_id'");
$sth->execute;
$sth->finish;
	
my %uniq = ();
$sth = $dbh->prepare("select subj_id from sre12_exclude");
$sth->execute;
while(my ($excl_subj) = $sth->fetchrow){
    ++$uniq{$excl_subj};
}
$sth->finish;

my @excl_list = ();

$sth = $dbh->prepare("select subj_id,spoke_to from sre12_subj_pairs where 
                             spoke_to = '$subj_id' or
                             subj_id = '$subj_id'");
$sth->execute;
while(my ($s1,$s2) = $sth->fetchrow){ 
    if($s1 == $subj_id){ push(@excl_list,$s2) }
    else{ push(@excl_list,$s1) }
}
$sth->finish;

foreach my $el(@excl_list){
    next if exists($uniq{$el});
    $uniq{$el}++;
    $sth = $dbh->prepare("insert into sre12_exclude(subj_id,spoke_to) values ('$subj_id','$el')");
    $sth->execute;
    $sth->finish;
}

$dbh->disconnect;

$pin = "XXXXX" unless $pin =~ /^\d{4,5}$/;
$number = "XXXXXXXXXXX" unless $number =~ /^\d{11}$/;

procwrite($procid,"getcallee_resp.txt","$pin\|$number");
procwrite($procid,"subj_id",$subj_id);
procwrite($procid,"number",$number);
procwrite($procid,"phone_id",$phone_id);
procwrite($procid,"group_id",$group_id);
procwrite($procid,"dbpin",$pin);

@{ $timearry{'exit'} } = (localtime)[0,1,2,3];



sub ohct {
    my $ret = 0;
    for(my $i = 0; $i < 48; ++$i){
	my $d = procread(sprintf("%0.2d",$i),"ohdur");
	print F "$d\n";
	if($d > 60){
	    ++$ret;
	}
    }
    return($ret);
}
