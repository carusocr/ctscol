#!C:\\Perl\\bin\\perl

use strict;
use YAML qw(LoadFile DumpFile);

my $vlcrt = my $vlcpid = undef;

my $yml_file = shift;
die "No such YAML $yml_file\n" unless -f $yml_file;

my $yml_init = LoadFile($yml_file);

foreach my $k(keys(%{ $yml_init->{'vlcenv'} })){
    $ENV{$k} = $yml_init->{'vlcenv'}->{$k};
}

opendir SRCDIR,"." || die "$!";
my @vsfiles = grep { -f && /\.vs$/ } readdir SRCDIR;
closedir SRCDIR;

for my $vsfile(@vsfiles){
    my $vlccmd_str = sprintf("%s %s %s",
			     $ENV{VLCEXEC},
			     $yml_init->{"vlcargs"}->{"argstr"},
			     $vsfile);

    print "$vlccmd_str\n";

    #system($vlccmd_str);

}

