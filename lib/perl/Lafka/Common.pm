package Lafka::Common;

use strict;
use warnings;

use File::Basename;
use File::Path;
#use Carp qw(confess);

## creates the directories we need for a file
sub prep4file {
  ## full file name
  my $fufi=shift;
  my $dir=dirname($fufi);
  if(-d $dir) {
    return 0;
  }
  mkpath($dir);
  return 1;
}

## tells us if we are on a tty
sub is_a_tty {
  no autodie;
  my $tty;
  if(open($tty, '+<', '/dev/tty')) {
    close $tty;
    return 1;
  }
  return 0;
}

1;
