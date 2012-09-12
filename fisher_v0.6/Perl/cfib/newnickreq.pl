use Getopt::Std;
use Data::UUID;
use lib "d:/fisher_v0.6/Perl/";
use FshPerl;
use Data::RandomPerson::Names::Female;
use Data::RandomPerson::Names::Male;

my %opts = ();
getopt('p:g:',\%opts);
my $pid = $opts{p};
my $gender = $opts{g};
die unless $pid =~ /\d+/;

my $r = undef;

if($gender =~ /F/i){
    $r = Data::RandomPerson::Names::Female->new();
}
else {
    $r = Data::RandomPerson::Names::Male->new(); 
}

my $name = $r->get();

print "$name\n";
