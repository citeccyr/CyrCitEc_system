package Ernad::Shonu;

use strict;
use warnings;

my $chain='0123456789abcdefghijklmnopqrstuvwxyz';
my $length=length($chain);
my @points=split('',$chain);

sub code {
  my $in=shift;
  my $out;
  my $t=$in % $length;
  if(($t - $in) == 0) {
    $out=$points[$t]
  }
  else {
    $out=&code(($in-$t)/$length) . $points[$t]
  }
  return $out;
}

sub decode {
  my $in=shift;
  my @chars=split('',$in);
  my $power=0;
  my $out=0;
  foreach my $char (reverse @chars) {
    my $digit=index($chain,$char);
    $out=$out + $digit * ($length ** $power);
    $power++;
  }
  return $out;
}

sub diff {
  my $big=shift;
  my $small=shift;
  $big=&decode($big);
  $small=&decode($small);
  my $diff=$big - $small;
  return $diff;
}
