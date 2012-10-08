#!c:/perl/bin/perl.exe

use DBI;

use lib "../";
use FshPerl;
use Semfile;

my $dbh = get_dbh();

my $r = FshPerl::get_phid($dbh,"99993","2155393412");

print "$r\n";

rel_dbh($dbh);



