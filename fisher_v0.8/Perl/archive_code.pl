#!d:/perl/bin/perl.exe
$ver = "v0.5";
($sec,$min,$hr,$day,$mth,$yr) = (localtime)[0,1,2,3,4,5];
$tarfile=sprintf("%0.4d%0.2d%0.2d\_%0.2d%0.2d%0.2d\_fisher_$ver\.tar",$yr+1900,$mth+1,$day,$hr,$min,$sec);
system("tar cf $tarfile Bin/*.vs Function/*.fun Include/*.inc Perl/cfib/*.pl Perl/fisher/*.pl Perl/*.pm");
print "$tarfile\n";


