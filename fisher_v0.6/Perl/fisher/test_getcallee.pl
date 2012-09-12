#!c:\\perl\\bin\\perl.exe

use DBI;

use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;

($s,$mi,$h,$d,$m,$y,$dow) = (localtime)[0,1,2,3,4,5,6];
$dstr = (qw/Su Mo Tu We Th Fr Sa/)[$dow];
#$timecond = sprintf("%%%s%%%0.2d%%",$dstr,$h);

$dstr = "Tu";
$h = "18";
$timecond = sprintf("%%%s%%%0.2d%%",$dstr,$h);



my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
                       die "Cannot connect to server\n";

my %sidtbl = ();
my $tdyrec_qry   = "d:\\fisher_v0.5\\Perl\\fisher\\tdyrecs.sql";
$/ = undef;
open F,"$tdyrec_qry" || die "$!";
$tdyrec_cmd = <F>;
close(F);
$/ = "\n";
my $sth = $dbh->prepare("$tdyrec_cmd");
$sth->execute;
while((my $sida, my $sidb) = $sth->fetchrow){
    ++$sidtbl{$sida};
    ++$sidtbl{$sidb};
}
$sth->finish;

my $sidstr = join(",",keys %sidtbl);

my $fullpool_qry = "d:\\fisher_v0.5\\Perl\\fisher\\testgetcallee.sql";
my $ldcpool_qry  = "d:\\fisher_v0.5\\Perl\\fisher\\getcleldc.sql";
my $qry = undef;

#if(ohct() > 0){
#    $qry = $ldcpool_qry;
#}
#else {
$qry = $fullpool_qry;
#}

print "Using $qry\n";

sub ohct {
    my $ret = 0;
    for(my $i = 0; $i < 48; ++$i){
	my $d = procread(sprintf("%0.2d",$i),"ohdur");
	print "$d\n";
	if($d > 60){
	    ++$ret;
	}
    }
    return($ret);
}

open F,"$qry" || die "$!";
while(<F>){
    next if /^\#/;
    $sqlcmd .= $_;

}
close(F);

print "$sqlcmd\n";

$sth = $dbh->prepare("$sqlcmd");
$sth->execute;

while(my ($subj_id,$pin,$fname,$lname,$phone_id,$number,$group_id) = $sth->fetchrow){
    print "$subj_id,$pin,$fname,$lname,$phone_id,$number,$group_id\n" if $number =~ /^1\d{10}$/;
}
$sth->finish;

#$sth = $dbh->prepare("select subj_id,spoke_to from sre12_subj_pairs where 
#                             spoke_to = '$subj_id' or
#                             subj_id = '$subj_id'");
#$sth->execute;
#while(my ($s1,$s2) = $sth->fetchrow){ 
#    if($s1 == $subj_id){ push(@excl_list,$s2) }
#    else{ push(@excl_list,$s1) }
#}
#$sth->finish;
#foreach my $el(@excl_list){
#    next if exists($uniq{$el});
#    $uniq{$el}++;
#    $sth = $dbh->prepare("insert into sre12_exclude(subj_id,spoke_to) values ('$subj_id','$el')");
#    $sth->execute;
#    $sth->finish;
#}


$dbh->disconnect;



