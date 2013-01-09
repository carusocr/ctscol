#!c:/perl/bin/perl.exe

use Archive::Tar;
use DBI;
use lib "../";
use FshPerl;
use File::Slurp;

my $pid = shift;

die unless procvalid($pid);
$pid=sprintf("%0.2d",$pid);

chdir("$proc_dir/$pid") || die "$!";

($sec,$min,$hr,$day,$mth,$yr) = (localtime)[0,1,2,3,4,5];
my $tarfile=sprintf("%0.4d%0.2d%0.2d\_%0.2d%0.2d%0.2d\.tar",$yr+1900,$mth+1,$day,$hr,$min,$sec);

my $tar = Archive::Tar->new();
my $side_id = undef;

if(-f "side_id"){
    read_file("side_id",\$side_id);

    opendir(DIR,".") || die "$!";
    my @inclfiles = grep { -f $_ && $_ !~ /\.tar$/ } readdir(DIR);
    closedir(DIR);
    
    if(scalar(@inclfiles) > 0){
	foreach my $file(@inclfiles){
	    print "$file\n";
	    $tar->add_files($file);
	    unlink($file);
	}
	$tar->write($tarfile);
    }
    
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("update sre12_io_calls set proctar = ? where side_id = ?");
    $sth->execute($tarfile,$side_id);
    $sth->finish;
    rel_dbh($dbh);
}




