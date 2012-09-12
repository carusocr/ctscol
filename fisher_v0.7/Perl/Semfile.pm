
package Semfile;

use strict;
use FileHandle;


sub new {
    my $class = shift(@_);
    my $filespec = shift(@_);

    my $fh = new FileHandle;
    $fh->open( ">$filespec" );
    chmod 0664, $filespec;	# make it ug+rw
    use Fcntl 'LOCK_EX';
    flock $fh, LOCK_EX;
    return bless {'fh' => $fh}, ref($class) || $class;
}

sub release {
    undef $_[0]{'fh'};
}
1; # End of module




