
package FshPerl;

use Readonly;
use File::Slurp;
use File::AtomicWrite;
use Exporter;
use base 'Exporter';
our @ISA = qw(Exporter);
our @EXPORT = qw(cvt_period   procwrite  procread load_tdyrec 
                 get_pool_qry ioc_update get_tod
		 %telco_mysql $dbistr    %projname %projtbl $proc_dir);
our $VERSION = 1.0;

our $proc_dir      = 'p:/proc';
our $tdyrec_file   = 'd:/fisher_v0.5/Perl/fisher/tdyrecs.sql';

our %pool_qryset   = ( FULL => 'd:/fisher_v0.5/Perl/fisher/getcallee.sql',
		       LDC  => 'd:/fisher_v0.5/Perl/fisher/getcleldc.sql' );

our %telco_mysql = ( host     => 'thalia2.ldc.upenn.edu',
		     database => 'telco_master',
		     userid   => 'toku',
		     passwd   => '________' );

our $dbistr = sprintf("DBI:mysql:host=%s;database=%s", $telco_mysql{host}, $telco_mysql{database});

$telco_mysql{dbistr} = $dbistr;

our %projname  = ( 3 => 'mx3',
		   1 => 'fsp',
		   2 => 'fsh' );

our %projtbl = ( subj       => { fsp => 'fsp_subj',       mx3 => 'mx3_subj'       },
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
    my $wfil = sprintf("%s/%0.2d/%s", $proc_dir, $pid, $k);
    if(-e $wfil){ unlink($wfil) }
    File::AtomicWrite->write_file({ file => $wfil, input => \$v });
}

sub procread {
    my ($pid,$k) = @_;
    $pid = sprintf("%0.2d",$pid);
    my $pfil = "$proc_dir/$pid/$k";
    my $rtn = -1;
    if(-e $pfil){
	read_file($pfil, buf_ref => \$rtn);
	chomp($rtn);
    }
    print "$rtn\n";
    return($rtn);
}

sub get_pool_qry {
    my ($mode) = @_;
    my $rtn = undef;
    read_file($pool_qryset{$mode}, buf_ref => \$rtn);
    return($rtn);
}

sub load_tdyrec {
    my($dbhref,$rtnref) = @_;
    my $tdyrec_qry = undef;
    if(read_file($tdyrec_file, buf_ref => \$tdyrec_qry)){
	my $sth = $dbhref->prepare($tdyrec_qry);
	$sth->execute;
	while((my $sida, my $sidb) = $sth->fetchrow){
	    ++$rtnref->{$sida};
	    ++$rtnref->{$sidb};
	}
	$sth->finish;
    }
}

sub ioc_update {
    my ($dbhref, $side_id, $field, $value) = @_;
    my $sth = $dbhref->prepare("update mx7spa_io_calls set $field = ? where side_id = ?");
    $sth->execute($value,$side_id);
    $sth->finish;
}

sub get_tod {

    my ($dbhref) = (@_);
    my $sth = $dbhref->prepare("select topic_id,topic_file from mx7spa_topics where tod_yn = ?");
    $sth->execute('Y');
    my @ret = $sth->fetchrow;
    $sth->finish;
    return(@ret);

}



1;



