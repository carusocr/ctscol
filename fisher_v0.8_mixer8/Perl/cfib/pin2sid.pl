#!c:/perl/bin/perl.exe

use Archive::Tar;
use DBI;
use lib "c:/fisher_v0.8/Perl/";
# use lib "c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl/";
use FshPerl;

my $proc_id = sprintf("%0.2d",shift);
my $pin = shift;

die "Invalid proc id $proc_id\n" unless $proc_id > 0;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
    die "Cannot connect to server\n";

# my $sth = $dbh->prepare("select subj_id from rats_subj where pin = ?");
my $sth = $dbh->prepare("SELECT p.id
						 FROM participants p
						 WHERE p.pin = ?");
$sth->execute($pin);
my ($subj_id) = $sth->fetchrow;
$sth->finish;

$subj_id = '99999' unless $subj_id =~ /\d+/;

print "$subj_id\n";
procwrite($proc_id,"ce_subj_id",$subj_id);
