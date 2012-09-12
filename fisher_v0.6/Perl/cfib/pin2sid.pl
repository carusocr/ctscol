#!c:/perl/bin/perl.exe

use DBI;
use lib "d:/fisher_v0.6/Perl/";
use FshPerl;

my $proc_id = sprintf("%0.2d",shift);
my $pin = shift;

die "Invalid proc id $proc_id\n" unless $proc_id > 0;

my $dbh = DBI->connect($telco_mysql{dbistr},$telco_mysql{userid},$telco_mysql{passwd}) || 
    die "Cannot connect to server\n";

my $sth = $dbh->prepare("select subj_id from rats_subj where pin = ?");
$sth->execute($pin);
my ($subj_id) = $sth->fetchrow;
$sth->finish;

$subj_id = '99999' unless $subj_id =~ /\d+/;

print "$subj_id\n";
procwrite($proc_id,"ce_subj_id",$subj_id);
