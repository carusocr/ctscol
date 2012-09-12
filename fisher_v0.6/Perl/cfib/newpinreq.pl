use DBI;
use Getopt::Std;
use lib "d:/fisher_v0.6/Perl/";
use FshPerl;
use Data::RandomPerson::Names::Female;
use Data::RandomPerson::Names::Male;

my %opts = ();
getopt('p:g:',\%opts);
my $pid = $opts{p};
my $cegend = $opts{g};

my ($crpin)  = procread($pid,'pin');
my ($cenick) = get_nick($cegend);

my $dbh = DBI->connect($telco_mysql{dbistr},
		       $telco_mysql{userid},
		       $telco_mysql{passwd}) || die "Cannot connect to server\n";

my $proc_qry = sprintf("call rats_genpin('%s','%s',%s,%s)",$crpin,$cenick,$cegend,'@rtn');

$dbh->do($proc_qry);
my $rpin = $dbh->selectrow_array('SELECT @rtn');

my $sth = $dbh->prepare("update telco_subjects set fname = ?,lname = ? where pin = ?");
$sth->execute($cenick,$crpin,$rpin);
$sth->finish;

$dbh->disconnect;

procwrite($pid,'ce_nick',  $cenick);
procwrite($pid,'preqresp', $rpin);
procwrite($pid,'ce_pin',   $rpin);

sub get_nick {

    my ($gend) = @_;
    my $r = undef;
    if($gend == 2){
	$r = Data::RandomPerson::Names::Female->new();
    }
    else {
	$r = Data::RandomPerson::Names::Male->new();
    }
    my $name = $r->get();
    return($name);

}
