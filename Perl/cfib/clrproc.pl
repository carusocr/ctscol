#!c:/perl/bin/perl.exe

use Archive::Tar;
use lib "c:/fisher_v0.8/Perl/";
use FshPerl;
use Semfile;
$pid = shift;
die "No such PID $pid\n" unless $pid =~ /\d+/ && $pid > 0;
die "Invalid proc $proc_dir\n" unless $proc_dir =~ /proc/;
$pid=sprintf("%0.2d",$pid);
die "Invalid pid $pid\n" unless -d "$proc_dir/$pid";
chdir("$proc_dir/$pid") || die "$!";

($sec,$min,$hr,$day,$mth,$yr) = (localtime)[0,1,2,3,4,5];

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

my $tarfile=sprintf("%0.4d%0.2d%0.2d\_%0.2d%0.2d%0.2d\.tgz",$yr+1900,$mth+1,$day,$hr,$min,$sec);
if($fc > 0 && ! -e $tarfile){
    $tar->write($tarfile, COMPRESS_GZIP);
}
