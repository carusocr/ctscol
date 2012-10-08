use lib "../";
use FshPerl;

my $report = "p:/proc/14/final_report";
my %rtn = ();

FshPerl::load_dtbl($report,\%rtn);
