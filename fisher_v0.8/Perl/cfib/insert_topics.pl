#!c:/perl/bin/perl.exe

use DBI;
use lib "d:/fisher_v0.5/Perl/";
use FshPerl;

my $dbh = DBI->connect($telco_mysql{dbistr},
		       $telco_mysql{userid},
		       $telco_mysql{passwd}) || 
    die "Cannot connect to server\n";


my $sth = $dbh->prepare( "insert into lre11_topics (topic_id, topic_file, summ_file, tod_yn) values (?,?,?,?)" );

for(my $i = 1; $i < 44; ++$i){
    my $tf = sprintf "T%0.2dENG.ul",$i;
    my $sf = sprintf "S%0.2dENG.ul",$i;
    $sth->execute($i,$tf,$sf,"N");
}

$sth->finish;




# +-------------+---------------+------+-----+---------+----------------+
# | Field       | Type          | Null | Key | Default | Extra          |
# +-------------+---------------+------+-----+---------+----------------+
# | topic_id    | int(11)       |      | PRI | NULL    | auto_increment |
# | topic_descr | varchar(250)  | YES  |     | NULL    |                |
# | topic_file  | varchar(80)   | YES  |     | NULL    |                |
# | summ_file   | varchar(80)   | YES  |     | NULL    |                |
# | tod_yn      | enum('Y','N') | YES  |     | NULL    |                |
# +-------------+---------------+------+-----+---------+----------------+
# 5 rows in set (0.00 sec)
