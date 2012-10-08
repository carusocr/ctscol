#!d:\\perl\\bin\\perl.exe

use Archive::Tar;
use DBI;
use lib "d:/fisher_v0.5/Perl/";
use FshPerl;
use Semfile;
$pid = shift;
die unless $pid =~ /\d+/ && $pid > 0;
die unless $proc_dir =~ /proc/;
$pid=sprintf("%0.2d",$pid);
die "Invalid pid $pid\n" unless -e "$proc_dir/$pid";
chdir("$proc_dir/$pid") || die "$!";

($sec,$min,$hr,$day,$mth,$yr) = (localtime)[0,1,2,3,4,5];
$tarfile=sprintf("%0.4d%0.2d%0.2d\_%0.2d%0.2d%0.2d\.tar",$yr+1900,$mth+1,$day,$hr,$min,$sec);

$tar = Archive::Tar->new();

opendir(DIR,".") || die "$!";
$fc=0;
while(defined($file= readdir(DIR))){
    next if ( $file =~ /\d+\_\d+/ || $file =~ /^\.+$/ );
    ++$fc;
    if($file =~ /^side_id/){
	open SI,"$file";
	$side_id = <SI>;
	close(SI);
    }

    $tar->add_files($file);
    unlink($file);
}
closedir(DIR);

if($fc > 0 && ! -e $tarfile){
    $tar->write($tarfile);
    my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd});
    my $sth = $dbh->prepare("update mx3_io_calls set proctar = '$tarfile' where side_id = '$side_id'");
    $sth->execute;
    $sth->finish;
    $dbh->disconnect;
}

