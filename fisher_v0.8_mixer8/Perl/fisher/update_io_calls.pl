#!c:/perl/bin/perl.exe

use strict;
use lib "../";
use DBI;
use FshPerl;
use Getopt::Std;
use Test::Taint;

my %opt = ( t => '', i => '', f => '', v => '');
getopts('t:i:f:v:', \%opt);

die "!!\n" unless untainted_ok_deeply(\%opt);

my $ioc_tbl = $opt{t};
my $side_id = $opt{i};
my $tvalue  = $opt{v};
my $tfield  = $opt{f};

die "Invalid tbl $ioc_tbl\n" unless $ioc_tbl =~ /[\w\d]+\_io_calls/;
die "Invalid side_id $side_id\n" unless $side_id =~ /^\d+$/;
die "!!\n" if sql_rej($tvalue) || sql_rej($tfield);

sub sql_rej {
    my ($t) = @_;
    return 1 if $t =~ /([\#\!\?\*\'\"]|select|delete|update|insert|grant|show|set|update|drop)/i;
}

my $dbh = get_dbh();

die "No such table $ioc_tbl\n" unless table_exists($dbh,$ioc_tbl);

my $sth = $dbh->prepare("update $ioc_tbl set $tfield = ? where side_id = ?");
$sth->execute($tvalue,$side_id);
$sth->finish;

rel_dbh();


