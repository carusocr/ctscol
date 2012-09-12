#!c:/perl/bin/perl.exe

use lib "../";
use FshPerl;
$pid=sprintf("%0.2d",shift);
die "$!" unless $pid > 0;
die "INvalid procdir $proc_dir\n" unless $proc_dir =~ /proc/;
chdir("$proc_dir/$pid") || die "$!";

opendir(DIR,".") || die "$!";
while(defined($file= readdir(DIR))){
    next if ( $file =~ /\d+\_\d+/ || $file =~ /^\.+$/ );
    unlink($file);
}
closedir(DIR);


