
package FshPerl;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION %telco_mysql %projname %projtbl $proc_dir);
@ISA = qw(Exporter);
@EXPORT = qw(cvt_period procwrite procread %telco_mysql %projname %projtbl $proc_dir);
$VERSION = 1.0;

$proc_dir = "p:/proc";

%telco_mysql = ( dbistr   => 'DBI:mysql:host=thalia2.ldc.upenn.edu;database=telco_master',
		 host     => 'thalia2.ldc.upenn.edu',
		 database => 'telco_master',
		 userid   => 'toku',
		 passwd   => '________' );

%projname  = ( 3 => 'mx3',
               1 => 'fsp',
               2 => 'fsh' );

%projtbl = ( subj       => { fsp => 'fsp_subj',       mx3 => 'mx3_subj'       },
             br_calls   => { fsp => 'fsp_br_calls',   mx3 => 'mx3_br_calls'   },
             exclude    => { fsp => 'fsp_exclude',    mx3 => 'mx3_exclude'    },      
             io_calls   => { fsp => 'fsp_io_calls',   mx3 => 'mx3_io_calls'   },
             subj_pairs => { fsp => 'fsp_subj_pairs', mx3 => 'mx3_subj_pairs' }, 
             topics     => { fsp => 'fsp_topics',     mx3 => 'mx3_topics'     } ); 



sub cvt_period {
    my $dat = shift;
    my ($um,$val) = $dat =~ /([A-Z])([\d\.]+)/;
    return("ERR($dat)") unless $um =~ /(D|H|M|S)/;
    if($um eq "H"){ $val = $val / 24 } 
    elsif($um eq "M"){ $val = cvt_period("H" . $val / 60) }
    elsif($um eq "S"){ $val = cvt_period("M" . $val / 60) } 
    else {}
    return($val);
}

sub procwrite {
    my ($pid,$k,$v) = @_;
    $pid = sprintf("%0.2d",$pid);
    open F,">$proc_dir/$pid/$k" || die "$!";
    print F "$v\n";
    close(F);
}

sub procread {
    my ($pid,$k) = @_;
    $pid = sprintf("%0.2d",$pid);
    my $pfil = "$proc_dir/$pid/$k";
    my $ret = -1;
    if(-e $pfil){
	open F,"$pfil" || die "$!";
	$ret = <F>;
	$ret =~ s/[\r\n]//g;
	close(F);
    }
    return($ret);
}

1;
