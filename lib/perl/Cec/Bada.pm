package Cec::Bada;

use strict;
use warnings;

use File::Slurper;
use Carp qw(confess);

use Cec::Dates;
use Cec::Paths;

my $bada_dir=$Cec::Paths::dirs->{'bada'};

our $ways;
$ways->{'change'}=1;
$ways->{'entry'}=1;

sub date_to_file {
  my $date=shift // confess "I need a data argument here.";
  if(not $date=~m|^\d{4}-\d{2}-\d{2}$|) {
    confess "You date '$date' is not to my liking!";
  }
  return substr($date,0,4).'/'.substr($date,5);
}


sub get_from_date {
  my $date=shift // confess "I need a data argument here.";
  if(not $date=~m|^\d{4}-\d{2}-\d{2}$|) {
    confess "You date '$date' is not to my liking!";
  }
  my $out;
  foreach my $way (keys %$ways) {
    my $file="$bada_dir/$way/".&date_to_file($date);
    if(not -f $file) {
      next;
    }
    my @lines=&File::Slurper::read_lines($file);
    foreach my $line (@lines) {
      $out->{$line}=1;
    }
  }
  return $out;
}

1;
