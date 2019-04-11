package Krichel::Shonu;

use strict;
use warnings;

my $chain='0123456789abcdefghijklmnopqrstuvwxyz';
my $length=length($chain);
my @points=split('',$chain);

sub make {
  my $in=shift;
  my $out;
  my $t=$in % $length;
  if(($t - $in) == 0) {
    $out=$points[$t]
  }
  else {
    $out=&make(($in-$t)/$length) . $points[$t]
  }
  return $out;
}

sub ekam {
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
  $big=&ekam($big);
  $small=&ekam($small);
  my $diff=$big - $small;
  return $diff;
}
