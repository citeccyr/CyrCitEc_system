package Cec::Processes;

use strict;
use warnings;

use Carp qw(confess);
use Proc::ProcessTable;

sub count_running {
  my $script=shift // confess "I need a script here.";
  my $t = Proc::ProcessTable->new( 'cache_ttys' => 1 );
  my $count=0;
  my $verbose=0;
  foreach my $p ( @{$t->table} ){
    my $cmd=$p->cmndline;
    if($cmd=~m|$script|) {
      if($verbose) {
	print "I see '$script' in '$cmd'\n";
      }
	$count++;
      next;
    }
    if($cmd) {
      if($verbose) {
	print "'$cmd' does not match '$script'\n";
      }
    }
  }
  return $count;
}

sub kill_all {
  my $script=shift // confess "I need a script here.";
  my $verbose=0;
  my $t = Proc::ProcessTable->new( 'cache_ttys' => 1 );
  my $count=0;
  foreach my $p ( @{$t->table} ){
    my $cmd=$p->cmndline;
    if(not $cmd=~m|$script|) {
      if($verbose) {
	#print "'$cmd' does not match '$script'\n";
	next;
      }
    }
    #print "I see '$script' in '$cmd'\n";
    $count++;
  }
}

1;
