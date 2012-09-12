#!D:\\Perl\\bin\\perl.exe

use DBI;
use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;

my $procid = shift;
$procid = sprintf("%0.2d", $procid); 

procwrite($procid,"getcallee_resp.txt","XXXX\|XXXXXXXXXX\n");

my ($s,$mi,$h,$d,$m,$y,$dow) = (localtime)[0,1,2,3,4,5,6];
my $dstr = (qw/Su Mo Tu We Th Fr Sa/)[$dow];
my $timecond = sprintf("%%%s%%%0.2d%%",$dstr,$h);

my $dbh = DBI->connect($dbistr,
		       $telco_mysql{userid},
		       $telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my %sidtbl = ();
load_tdyrec($dbh,\%sidtbl);
my $sidstr = join(",",keys %sidtbl);

my $sqlcmd = get_pool_qry('FULL');
$sqlcmd    =~ s/AVSTRINGREPL/$timecond/;
$sqlcmd    =~ s/SIDRECTDYREPL/$sidstr/;

my $gclock = Semfile->new("$proc_dir/gc_lock");

my $sth = $dbh->prepare("$sqlcmd");

$sth->execute;
my ($subj_id,$pin,$phone_id,$number,$group_id) = $sth->fetchrow;
$sth->finish;

$sth = $dbh->prepare("update telco_subjects set CIP = ? where subj_id = ?");
$sth->execute('Y',$subj_id);
$sth->finish;
$gclock->release;

$sth = $dbh->prepare("delete from mx7spa_exclude where subj_id = ?");
$sth->execute($subj_id);
$sth->finish;
	
my %uniq = ();
$sth = $dbh->prepare("select subj_id from mx7spa_exclude");
$sth->execute;
while(my ($excl_subj) = $sth->fetchrow){
    ++$uniq{$excl_subj};
}
$sth->finish;

my @excl_list = ();

$sth = $dbh->prepare("select subj_id,spoke_to from mx7spa_subj_pairs where 
                             spoke_to = ? or subj_id = ?");
$sth->execute($subj_id,$subj_id);
while(my ($s1,$s2) = $sth->fetchrow){ 
    if($s1 == $subj_id){ push(@excl_list,$s2) }
    else{ push(@excl_list,$s1) }
}
$sth->finish;

foreach my $el(@excl_list){
    next if exists($uniq{$el});
    $uniq{$el}++;
    $sth = $dbh->prepare("insert into mx7spa_exclude(subj_id,spoke_to) values (?,?)");
    $sth->execute($subj_id,$el);
    $sth->finish;
}

$dbh->disconnect;

$pin = "XXXXX" unless $pin =~ /^\d{4,5}$/;
$number = "XXXXXXXXXXX" unless $number =~ /^\d{11}$/;

my %proc_ud = ('getcallee_resp.txt' => sprintf("%s|%s",$pin,$number),
	       'subj_id'            => $subj_id,
	       'number'             => $number,
	       'group_id'           => $group_id,
	       'phone_id'           => $phone_id,
	       'dbpin'              => $pin);

foreach my $pud_key(keys(%proc_ud)){
    printf "%s %s %s\n",$procid,$pud_key,$proc_ud{$pud_key};
    procwrite($procid,$pud_key,$proc_ud{$pud_key});
}

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
