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
