package Cec::Common;

use strict;
use warnings;

sub isatty() {
  no autodie;
  my $tty;
  if(open($tty, '+<', '/dev/tty')) {
    close $tty;
    return 1;
  }
  return 0;
}

1;
