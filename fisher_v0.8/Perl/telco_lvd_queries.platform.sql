##
## queries to be used by the LVDID platform during call progress
##
## Each query is expressed as it would be used in a Perl/DBI script,
## involving calls through the DBI connection object "$dbh" to prepare
## statements, as well as to execute them and perform other functions;
## "?" placeholders are used where appropriate for values in queries.
##
## Where necessary, we'll indicate blocks of code that need to be made
## atomic by a semaphore on the platform.
##
## Among the possible outcomes for each query, results that lead
## directly to call termination will include a parameter value to be
## used in a final update to "lvd_io_calls".

##
## -------------------------------
## 1. within the "answer" process:
##
## ----
## A. at some point prior to pin validation for incoming call: insert io_calls record
##     input from vos:
##        ANI, line_id, proc_id
##     return to vos:
##        lvd_io_calls.side_id or failure code
##     in case of failure: advise caller and terminate call

my $sth = $dbh->prepare( "insert into lvd_io_calls ( io_start, io_phnum,
                          io_proc_id, io_line_id ) values (NOW(),?,?,?)" );
  # get semaphore lock
$sth->execute( $ani, $line_id, $proc_id );
my $side_id = $dbh->{mysql_insertid};

$sth->finish;
$dbh->commit;
  # release lock

my $retrn = $side_id || "DB_FAILED";
print "$retrn\n";

##
## ----
## B. validate incoming PIN: if valid, update "cip" for this subject
##     input from vos:
##        DTMF values from caller in response to PIN and ANI/PHONE_NUMBER (dial from) prompts
##     return to vos:
##        caller's subj_id, group_id, subgroup_id (== partner's subj_id) or failure code
##     in case of failure: advise caller and terminate call

my ( $subj_id, $active, $contact_phone, $calls_done, $max_allowed, $group_id, $partner_id ) = 
   $dbh->selectrow_array( "select subj_id, active, contact_phone, calls_done, max_allowed, group_id,
                           subgroup_id from lvd_subj where pin=?", {}, $pin );
if ( !defined( $subj_id )) {
    print "INVALD_PIN\n";
}
elsif ( !defined( $active ) or $active ne 'Y' ) {
    print "INACTV_PIN\n";
}
elsif ( !defined( $partner_id )) {
    print "NOPAIR_SBJ\n";
}
elsif ( $calls_done >= $max_allowed ) {
    print "CLDONE_PIN\n";
}
elsif ( $contact_phone ne $dialin_phone ) {
    print "WRONG_PHONE\n";
}
else {
    my $sth = $dbh->prepare( "update telco_subjects set cip='Y' where subj_id=?" );
    $sth->execute( $subj_id );
    $sth->finish;
    $dbh->commit;
    print "$subj_id $group_id $partner_pin $partner_phnum\n";
}

##
## If dial-out to the partner fails (cannot bridge): advise caller, terminate(PAIR_UNAV).
## Otherwise, at the point where bridging occurs, one line/proc is
## designated the master and performs the following:
## (for now, we'll assume that the caller's line/proc is always the master)

##
## ----
## C. establish bridge: create lvd_br_calls entry, update master's io_calls entry
##     input from vos:
##        side_id obtained at step A,
##        pair_side_id from partner's dial-out proc, 
##        DTMF values of phone_set, phone_type prompts from master
##     return to vos:
##        lvd_br_calls.call_id or failure code
##     in case of failure: save insert and update statements to special log file

my $sth = $dbh->prepare( "insert into lvd_br_calls ( cra_side_id, crb_side_id, call_date )
                          values (?,?,NOW())" );
  # get semaphore lock
$sth->execute( $side_id, $partner_id );
my $br_call_id = $dbh->{mysql_insertid};

$sth->finish;
$dbh->commit;
  # release lock

$sth = $dbh->prepare( "update lvd_io_calls set subj_id=?, bridged_to=?, br_call_id=?,
                       phoneset=?, phonetype=? where side_id=?" );

$sth->execute( $subj_id, $pair_side_id, $br_call_id, $mphoneset, $mphonetype, $side_id );
$sth->finish;
$dbh->commit;

my $retrn = $br_call_id || "DB_FAILED";
print "$retrn\n";

##
## ----
## D. termination: do final updates to lvd_br_calls, telco_subjects and/or lvd_io_calls
##     input from vos:
##        termination status
##        side_id from step A
##        and if present:
##           subj_id from step A
##           br_call_id from step C
##           filesiza, filesizb
##     return to vos:
##        (nothing)
##     in case of failure: save update statement(s) to special log file

my $sth = $dbh->prepare( "update lvd_io_calls set io_end=NOW(), io_hup_status=? where side_id=?" );
$sth->execute( $term_status, $side_id );
$sth->finish;

if ( $subj_id ) {
    $sth = $dbh->prepare( "update telco_subjects set cip='N' where subj_id=?" );
    $sth->execute( $subj_id );
    $sth->finish;
}
if ( $br_call_id ) {
    $sth = $dbh->prepare( "update lvd_br_calls set filesiza=?, filesizb=?,
                           hup_status=? where call_id=?" );
    $sth->execute( $filesiza, $filesizb, $term_status, $br_call_id );
    $sth->finish;
}
$dbh->commit;


##
## -------------------------------
## 2. within the "dialer" process:
##
## ----
## A. get the partner's pin & phone number, insert io_call row for dial-out, update cip
##      input from vos:
##         line_id, proc_id, partner's subj_id
##      return to vos:
##         pair_pin, pair_phnum, pair_side_id; or failure code
##      in case of failure: advise caller and terminate call (in "answer" process)

my ( $pair_phid, $pair_phnum, $pair_pin ) = 
   $dbh->selectrow_array( "select p.phone_id, p.phone_number, s.pin from telco_phones p, 
                           telco_subjects s where p.subj_id=s.subj_id and 
                           s.subj_id=?", {}, $partner_id );

my ( $pair_side_id, $retrn );

if ( $pair_phid and $pair_phnum and $pair_pin ) {
    my $sth = $dbh->prepare( "insert into lvd_io_calls ( io_start, phone_id,
                              io_proc_id, io_line_id ) values (NOW(),?,?,?)" );
  # get semaphore lock
    $sth->execute( $pair_phid, $line_id, $proc_id );
    $pair_side_id = $dbh->{mysql_insertid};

    $sth->finish;
  # release lock

    $sth = $dbh->prepare( "update telco_subjeccts set cip='Y' where subj_id=?" );
    $sth->execute( $partner_id );
    $sth->finish;
    $dbh->commit;

    $retrn = ( $pair_side_id ) ? "$pair_pin $pair_phnum $pair_side_id" : "DB_FAILED";
}
else {
    $retrn = "INCOMPL_SBJ";
}
print "$retrn\n";

##
## The dialer process uses the pin and phnum values to contact and
## validate the callee; this may fail for any of several reasons, in
## which case dialer proceeds to its own terminate() function, with a
## parameter to categorize the failure.
## Otherwise, at the point where bridging occurs, the dialer is
## assumed to be the "slave" channel, and does the following:

##
## ----
## B. establish bridge: update dialer's io_calls entry
##     input from vos:
##         partner's subj_id as provided to dialer step A
##         $pair_side_id returned at dialer step A,
##         master's $side_id and $br_call_id,
##         DTMF values of phone_set, phone_type prompts from dialer
##     return to vos:
##         (nothing)
##     in case of failure: save update statement to special log file

$sth = $dbh->prepare( "update lvd_io_calls set subj_id=?, bridged_to=?, br_call_id=?,
                       phoneset=?, phonetype=? where side_id=?" );

$sth->execute( $partner_id, $side_id, $br_call_id, $sphoneset, $sphonetype, $pair_side_id );
$sth->finish;
$dbh->commit;

##
## ----
## C. termination: do final updates to lvd_io_calls for the dialer/slave side
##     input from vos:
##          dialer termination status,
##          pair_side_id from dialer step A
##     return to vos:
##          (nothing)
##     in case of failure: save update statement to special log file


my $sth = $dbh->prepare( "update lvd_io_calls set io_end=NOW(),
                          io_hup_status=? where side_id=?" );
$sth->execute( $dterm_status, $pair_side_id );
$sth->finish;

$sth = $dbh->prepare( "update telco_subjects set cip='N' where subj_id=?" );
$sth->execute( $partner_id );
$sth->finish;
$dbh->commit;

