package Krichel::Shoti;

use strict;
use warnings;

use Carp qw(confess);
use Date::Format;

use Krichel::Shonu;

## date -d 1993-02-01 +%s --> Mon Feb  1 00:00:00 UTC 1993
my $sot=728524800;

sub make {
  my $in=shift // confess "I need a time here.";
  $in=$in-$sot;
  if($in < 0) {
    confess "Your time is after the start of time.";
  }
  my $shonu=&Krichel::Shonu::make($in);
  return $shonu;
}

## opposite of make
sub ekam {
  my $in=shift;
  if(not is($in)) {
    confess "You input '$in' does not look like a shoti."
  }
  my $out=&Krichel::Shonu::ekam($in);
  $out=$out+$sot;
  return $out;
}

sub now {
  my $now=time();
  my $shoti=&make($now);
  return $shoti;
}

sub pretty {
  my $in=shift // confess "I need some input here.";
  my $time;
  if(not is($in)) {
    $time=$in;
  }
  else {
    $time=ekam($in);
  }
  my $pretty=time2str("%Y\x{2012}%m\x{2012}%d %H:%M:%S", $time);
  return $pretty;
}

sub is {
  my $in=shift // confess "I need some input here.";
  if($in=~m|^[0-9a-z]{6}$|) {
    return 1;
  }
  return 0;
}

sub ago {
  my $in=shift // confess "I need some input here.";
  if(not &is($in)) {
    confess "You input '$in' does not look like a shoti."
  }
  my $time=&ekam($in);
  my $age=time()-$time;
  return $age;
}

## unused, slated for removal 2018-12-28
### old to new shoti
#sub convert {
#  my $in=shift // confess "I need some input here.";
#  my $time=&Krichel::Shonu::ekam($in);
#  my $shoti=&make($time);
#  return $shoti;
#}

sub compare {
  my $early=shift // confess "I need an early date defined.";
  if(not $early) {
    $early='000000';
  }
  elsif(not is($early)) {
    confess "Your early '$early' is not a shoti.";
  }
  my $late=shift // confess "I need a late date defined.";
  if(not $late) {
    $late='000000';
  }
  elsif(not is($late)) {
    confess "Your late '$late' is not a shoti.";
  }
  if(($late cmp $early) >= 0) {
    return 1;
  }
  return 0;
}

sub compare_strict {
  my $early=shift // confess "I need an early date defined.";
  if(not $early) {
    $early='000000';
  }
  elsif(not is($early)) {
    confess "Your early '$early' is not a shoti.";
  }
  my $late=shift // confess "I need a late date defined.";
  if(not $late) {
    $late='000000';
  }
  elsif(not is($late)) {
    confess "Your late '$late' is not a shoti.";
  }
  if(($late cmp $early) > 0) {
    return 1;
  }
  return 0;
}
