
package FshPerl;

use Readonly;
use File::Slurp;
use File::AtomicWrite;
use Digest::MD5::File;
use YAML qw(LoadFile DumpFile);
use Exporter;
use base 'Exporter';
@ISA = qw(Exporter);
our @EXPORT = qw(get_dbh        rel_dbh       cvt_period
                 procwrite      procread      table_exists
                 ymlset         get_pool_qry  load_tdyrec
                 replstr        ioc_update    get_tod  get_phid
                 set_cip        set_sut run_pool_qry  clear_excl_list
                 init_excl_list npavalid      procvalid
                 load_24hrrecs   load_callct  get_reclen $proc_dir %telco_mysql %lui %collection);

our $VERSION = 1.2;

my $fshyml = LoadFile('c:/cygwin/usr/local/src/ctscol/fisher_v0.8/Perl/FshPerl.yml');

our $proc_dir  = $fshyml->{proc}->{proc_dir};
our $dberr_dir = $fshyml->{dberr}->{dberr_dir};

our %telco_mysql = ();
ymlset($fshyml,'telco_mysql',\%telco_mysql);

our %lui = ();
ymlset($fshyml,'lui',\%lui);

our %collection = ();
ymlset($fshyml,'collection',\%collection);

our %projname = ();
ymlset($fshyml, 'projname', \%projname);

%projtbl =();
ymlset($fshyml,'projtbl',\%projtbl);

our %fisher_qryfiles = ();
ymlset($fshyml,'fisher_qryfiles',\%fisher_qryfiles);

our %fisher_qryset = ();
ymlset($fshyml,'fisher_qryset',\%fisher_qryset);

our $dbh = undef;

sub get_dbh {
    $dbh = DBI->connect($telco_mysql{dbistr},
			$telco_mysql{userid},
			$telco_mysql{passwd}) || die $DBI::errstr;

    $dbh->{HandleError} = sub {
	my ($errstr,$handle) = @_;
	my $type = $handle->{'Type'};
	my $db   = $handle->{'Database'};
	my $em = sprintf("%s\t%s\t%s\t%s\n",$errstr,$db,$type,$0);
	my $errfile = sprintf("%s/%s_%s.err",$dberr_dir,time(),$$);
	File::AtomicWrite->write_file({ file => $errfile, input => \$em });
	die;
    };
    $dbh->{ShowErrorStatement} = 1;
    $dbh->{RaiseError} = 1;
    $dbh->{AutoCommit} = 0;
    return($dbh);
}

sub rel_dbh {
    my ($dbhref) = @_;
    $dbhref->commit;
    $dbhref->disconnect;
}

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
    my $pfil = sprintf("%s/%0.2d/%s", $proc_dir, $pid, $k);
    my $rtn = -1;
    if(-e $pfil){
	read_file($pfil, buf_ref => \$rtn);
	chomp($rtn);
    }
    return($rtn);
}

sub table_exists {
    my ($dbhref,$tbl) = @_;
    my @tblset = $dbhref->tables('','','','TABLE');
    return(grep(/$tbl/,@tblset));
}

sub ymlset {
    my ($ymlref, $section, $hash_ref ) = @_;
    foreach my $section_key(keys(%{ $ymlref->{$section} })){
	$hash_ref->{$section_key} = $ymlref->{$section}->{$section_key};
    }
}

sub get_pool_qry {
    my ($mode,$tcrepl,$sidrepl) = @_;
    my $rtn = undef;
    read_file($fisher_qryfiles{$mode}, buf_ref => \$rtn);
    $rtn =~ s/AVSTRINGREPL/$tcrepl/;
    $rtn =~ s/SIDRECTDYREPL/$sidrepl/;
    return($rtn);
}

sub load_24hrrecs {
    my($dbhref,$rtnref) = @_;
    my $tdyrec_qry = undef;
    if(read_file($fisher_qryfiles{'24HRRECS'}, buf_ref => \$tdyrec_qry)){
	my $sth = $dbhref->prepare($tdyrec_qry);
	$sth->execute;
	while(my ($subjA,$subjB,$hrs,$prevcd,$activeA,$activeB) = $sth->fetchrow){
	    ++$rtnref->{$subjA} unless $activeA =~ /^T$/;
	    ++$rtnref->{$subjB} unless $activeB =~ /^T$/;
	}
	$sth->finish;
    }
}

sub load_callct {
    my ($dbhref, $pid,$tblref) = @_;
    my $callct = undef;
    my $rtn = undef;
    if(read_file($fisher_qryfiles{CALLCT}, buf_ref => \$callct)){

	print "$callct\n";

	my $sth = $dbhref->prepare($callct);

	$sth->execute($tblref->{CRA_SUBJID},$tblref->{CRA_SUBJID});

	print "post qrya\n";

	($tblref->{CRA_SUBJID_CALLCT}) = $sth->fetchrow;

	$sth->execute($tblref->{CRB_SUBJID},$tblref->{CRB_SUBJID});

	($tblref->{CRB_SUBJID_CALLCT}) = $sth->fetchrow;

	$sth->finish;

	printf "%s\t%s\n", $tblref->{CRA_SUBJID_CALLCT},$tblref->{CRB_SUBJID_CALLCT};
    }
}

sub load_tdyrec {
    my($dbhref,$rtnref) = @_;
    my $tdyrec_qry = undef;
    if(read_file($fisher_qryfiles{TDYRECS}, buf_ref => \$tdyrec_qry)){
	my $sth = $dbhref->prepare($tdyrec_qry);
	$sth->execute;
	while((my $sida, my $sidb) = $sth->fetchrow){
	    ++$rtnref->{$sida};
	    ++$rtnref->{$sidb};
	}
	$sth->finish;
    }
}

sub init_dtbl {
    my ($tblref) = @_;
    my @fields = qw(CALL_ID     FILA        FILB       FILESIZA   FILESIZB 
                    SUBJ_ID     CE_SUBJ_ID  CRA_SUBJID CRB_SUBJID TIMESTAMP 
                    PIN         NUMBER      PAIR       PAIRNUMBER MYNOISEYN
                    PAIRNOISEYN MYPHNSET    PAIRPHNSET MYPHNTYPE  PAIRPHNTYPE 
                    TOPIC       TOPIC_ID    RECORDING  RUNTIME    POSANSR
                    POSPIN      HUPB4BRIDGE SHORTREC   FULLREC    EMPTYKUE 
                    POSOFFHOOK  SUCCESS     NOREC      TOPREJECT  TOHTIME
                    CRA_SIDEID  CRB_SIDEID  TERMSTAT);
    while(my $nf = shift(@fields)){ $tblref->{$nf} = undef }
    $tblref->{SUTVAL} = '01:00';
    $tblref->{CIP}    = 'N';
}

sub load_dtbl {
    my ($pid, $ifil, $tblref) = @_;
    my $aref = [];
    $aref = read_file($ifil, chomp => 1, array_ref => 1);
    map { chomp; 
	  my $x = []; 
	  @{$x} = split /\=/; 
	  if(scalar(@{$x}) == 2){ $tblref->{ $x->[0] } = $x->[1]; }
    } @{ $aref };
    
    if($tblref->{CRA_SIDEID} == -1){ $tblref->{CRA_SIDEID} = procread($pid,'side_id') }
    if($tblref->{CRB_SIDEID} == -1){ $tblref->{CRB_SIDEID} = procread($pid,'ce_side_id') }
    if($tblref->{CRA_SUBJID} == -1){ $tblref->{CRA_SUBJID} = procread($pid,'subj_id') }
    if($tblref->{CRB_SUBJID} == -1){ $tblref->{CRB_SUBJID} = procread($pid,'ce_subj_id') }

    my %reduce = ();

    for(sort keys %{ $tblref }){
	next if $tblref->{$_} == -1;
	next unless defined($tblref->{$_});
	$reduce{$_} = $tblref->{$_};
    }

    %{ $tblref } = ();

    for(sort keys %reduce){ $tblref->{$_} = $reduce{$_} }

    for(sort keys %{ $tblref }){
	printf "%s\t%s\n",$_,$tblref->{$_};
    }

    my %chck = ();
    my %fn   = ( FILA => 'FILESIZA', FILB => 'FILESIZB');
    my $srate = 8000;

    foreach my $k (keys(%fn)){
	if(exists($tblref->{$k}) && -f $tblref->{$k}){
	    my $bytecount = -s $tblref->{$k};
	    $tblref->{ $k . "_DURATION" } = int($bytecount/$srate);
	    $chck{ $fn{$k} } = $bytecount;
	    $tblref->{ $k . '_MD5' } = Digest::MD5::File::file_md5_hex($tblref->{$k});
	    if($tblref->{ $fn{$k} } != $chck{ $fn{$k} }){
		$tblref->{ $fn{$k} } = $chck{ $fn{$k} };
	    }
	    my ($path,$file) = $tblref->{ $k } =~ /^(.*)[\/\\]([^\\\/]+)$/;
	    $tblref->{ $k . '_NAME' } = $file;
	    $tblref->{ $k . '_PATH' } = $path;

	    if($tblref->{ $k . "_DURATION" } >= 300){
		$tblref->{TERMSTAT} = 'FULLREC';
		$tblref->{SUTVAL} = '15:00';
		$tblref->{FULLREC} = 'yes';
		$tblref->{SHORTREC} = 'no';
		$tblref->{NOREC} = 'no';
		if($tblref->{RUNTIME} !~ /\d/ || 
		   $tblref->{RUNTIME} < $tblref->{ $k . "_DURATION" }){
		    $tblref->{RUNTIME} = $tblref->{ $k . "_DURATION" };
		} 
	    }
	    
	}
    }
    
    foreach my $sid(qw/CRA_SUBJID CRB_SUBJID/){
	if($tblref->{$sid} !~ /^\d+$/){
	    $tblref->{$sid} = procread($pid,lc($sid));
	}
    }
}

sub replstr {
    my ($q,$r) = @_;
    if($q =~ /REPLSTR/){
	$q =~ s/REPLSTR/$r/;
    } else { $q = -1 }
    return($q);
}

sub ioc_update {
    my ($dbhref, $side_id, $field, $value) = @_;
    my $sth = $dbhref->prepare(replstr($fisher_qryset{"ioc"},$field));
    $sth->execute($value,$side_id);
    $sth->finish;
}

sub get_reclen {
    my ($dbhref,$project) = @_;
    # fixme - no table for project paramenters, yet #
    return(1000);
}

sub get_tod {

    my ($dbhref) = (@_);
    my $sth = $dbhref->prepare($fisher_qryset{tod});
    $sth->execute('Y');
    my @ret = $sth->fetchrow;
    $sth->finish;
    return(@ret);

}

sub get_phid {
    my ($dbhref,$sid,$number) = @_;
    
    $number =~ s/[^\d]//g;
    if(length($number) == 10 && $number !~ /^1/){
	$number = 1 . $number;
    }

    my $sth = $dbhref->prepare('select phone_id from telco_phones where subj_id = ? and phone_number like ?');
    $sth->execute($sid,sprintf("%%%s%%",$number));
    my ($rtn) = $sth->fetchrow;
    $sth->finish;

    if($rtn !~ /\d+/){
	$sth = $dbhref->prepare('insert into telco_phones (phone_id,subj_id,phone_number) values (NULL,?,?)');
	$sth->execute($sid,$number);
	$sth->finish;
	$rtn = get_phid($dbhref,$sid,$number);
    }

    return($rtn);
}

sub set_cip {
    my ($dbhref, $sid,$state) = @_;
    my $sth = $dbhref->prepare($fisher_qryset{cip});
    $sth->execute($state,$sid);
    $sth->finish;
}

sub set_sut {

    my ($dbhref, $sid,$ivl) = @_;
    my $sth = $dbhref->prepare($fisher_qryset{sut});
    $sth->execute($ivl,$sid);
    $sth->finish;

}

sub run_pool_qry {

    my ($dbhref, $qref, $rtnref) = @_;
    $sth = $dbh->prepare(${ $qref });
    $sth->execute;
    @{ $rtnref } = $sth->fetchrow;
    $sth->finish;
    
}

sub clear_excl_list {
    my ($dbhref,$sid) = @_;
    $sth = $dbh->prepare($fisher_qryset{excl_clr});
    $sth->execute($sid);
    $sth->finish;
}

sub init_excl_list {
    my ($dbhref,$sid) = @_;

    my $sth = undef;
    my %uniq = ();
    my @excl_list = ();

    $sth = $dbhref->prepare($fisher_qryset{excl_get});
    $sth->execute;
    while(my ($excl_subj) = $sth->fetchrow){ ++$uniq{$excl_subj} }
    $sth->finish;

    $sth = $dbhref->prepare($fisher_qryset{excl_pairs});
    $sth->execute($sid,$sid);
    
    while(my ($s1,$s2) = $sth->fetchrow){ 
	if($s1 == $sid){ push(@excl_list,$s2) }
	else{ push(@excl_list,$s1) }
    }
    $sth->finish;

    $sth = $dbh->prepare($fisher_qryset{excl_insrt});
    foreach my $el(@excl_list){
	next if exists($uniq{$el});
	$uniq{$el}++;
	$sth->execute($sid,$el);
    }
    $sth->finish;

}

sub npavalid {
    my $rtn = undef;
    my ($tstref) = @_;

    if(length(${ $tstref }) == 11 && ${ $tstref } =~ /^1/){
	++$rtn;
    }
    elsif(length(${ $tstref }) == 10 && ${ $tstref } !~ /^1/){
	${ $tstref } = 1 . ${ $tstref };
	++$rtn;
    }
    else {}

    return($rtn);
    
}

sub procvalid {
    my ($tstpid) = @_;
    my $procloc  =  sprintf("%s/%0.2d", $proc_dir, $tstpid);
    my $rtn      = undef;

    if($tstpid > 0 && 
       -d $procloc && 
       -r $procloc && 
       -w $procloc && 
       -x $procloc){
	$rtn = $procloc;
    }
    return($rtn);
}

1;
