
use Getopt::Std;
use Data::UUID;
use lib "d:/fisher_v0.6/Perl/";
use FshPerl;
my %opts = ();
getopt('p:',\%opts);
my $pid = $opts{p};
die unless $pid =~ /\d+/;
my $uuid_obj = new Data::UUID;
procwrite($pid,"uuid",$uuid_obj->create_str());

