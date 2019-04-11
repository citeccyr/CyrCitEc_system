package Cec::Processes;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Proc::ProcessTable;

sub count_running {
  my $script=shift // confess "I need a script here.";
  my $t = Proc::ProcessTable->new( 'cache_ttys' => 1 );
  my $count=0;
  my $verbose=0;
  foreach my $p ( @{$t->table} ){
    my $cmd=$p->cmndline // next;
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

sub kill_recent_duplicates {
  my $verbose = shift // 0;
  $verbose=1;
  my $t = new Proc::ProcessTable;
  my $parts={};
  my $counts={};
  foreach my $p ( @{$t->table} ) {
    my $pid=$p->pid;
    my $cmd=$p->cmndline;
    my $time=$p->time();
    if(not $cmd=~m|/recitex\.pl|) {
      next;
    }
    if($verbose) {
      print "cmd is $cmd\n";
    }
    foreach my $target (split(/\s+/, $cmd)) {
      if(not $target=~m|pdf-stream\.json$|) {
	next;
      }
      if(not $counts->{$target}) {
	$counts->{$target}=1;
      }
      else {
	$counts->{$target}++;
      }
      $parts->{$target}->[$counts->{$target}-1]->{$time}=$pid;
      print "part is " . Dumper $parts;
    }
  }
  my $argmaxes={};
  my $maxes={};
  foreach my $target (keys %$parts) {
    if($verbose) {
      print "target $target\n";
    }
    if(scalar(@{$parts->{$target}}) == 2) {
      if($verbose) {
	print "I see no duplicate for $target\n";
	delete $parts->{$target};
      }
      next;
    }
    #else {
    #  die scalar(@{$parts->{$target}})
    #}
    foreach my $couple (@{$parts->{$target}}) {
      my @keys= keys %{$couple};
      my $time = $keys[0];
      my $pid = $couple->{$time} // die;
      if(not $argmaxes->{$target}) {
	$argmaxes->{$target}=$pid;
	$maxes->{$target}=$time;
	next;
      }
      if($time < $maxes->{$target}) {
	next;
      }
      $argmaxes->{$target}=$pid;
      $maxes->{$target}=$time;
    }
    if($verbose) {
      print "argmaxes\n";
      print Dumper $argmaxes;
      print "maxes\n";
      print Dumper $maxes;
    }
    foreach my $target (keys %$parts) {
      if($verbose) {
	print "target $target\n";
      }
      foreach my $couple (@{$parts->{$target}}) {
	my @keys= keys %{$couple};
	my $time = $keys[0];
	my $pid = $couple->{$time} // die;
	if($pid eq $argmaxes->{$target}) {
	  print "I keep $pid\n";
	  next;
	}
	if($verbose) {
	  print "Cec::Processes: I kill $pid\n";
	}
	kill('KILL', $pid);
      }
    }
  }
}

1;
