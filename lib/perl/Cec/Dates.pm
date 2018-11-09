package Cec::Dates;

use strict;
use warnings;

use Carp qw(cluck longmess shortmess croak confess);
use Data::Dumper;
use Date::Calc qw(Add_Delta_Days);
use Date::Format;

use Ernad::Shoti;

sub regular_date {
  my $in=shift;
  if($in=~m|(\d)-(\d{2})-(\d{4})|) {
    return "$3-$2-0$1";
  }
  if($in=~m|(\d{2})-(\d)-(\d{4})|) {
    return "$3-0$2-$1";
  }
  if($in=~m|(\d)-(\d)-(\d{4})|) {
    return "$3-0$2-0$1";
  }
  if($in=~m|(\d{2})-(\d{2})-(\d{4})|) {
    return "$3-$2-$1";
  }
  return $in;
}


my $seconds_in_a_day=24*60*60;
my $format='%Y-%m-%d';

sub mtime {
  my $file=shift // confess "I need a file here.";
  if(not -f $file) {
    confess "I can't see the file $file.";
  }
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks)
    = stat($file);
  return $mtime;
}

sub mdate {
  my $file=shift // confess "I need a file here.";
  my $time=&mtime($file);
  my $date=time2str($format,$time);
  return $date;
}

sub set_ago {
  my $date=shift;
  my $shift=shift // confess "I need an operator here.";
  $date=~m|^(\d{4})-(\d{2})-(\d{2})$| or confess "I need a better date that '$date'";
  my $year=$1;
  my $month=$2;
  my $day=$3;
  my @dated=&Add_Delta_Days($year,$month,$day,$shift);
  $year=$dated[0];
  $month=$dated[1];
  if(length($month)<2) {
    $month="0$month";
  }
  $day=$dated[2];
  if(length($day)<2) {
    $day="0$day";
  }
  $date="$year-$month-$day";
  return $date;
}

## $in has dates as keys
sub ge_earliest_date_from_hash {
  my $in=shift;
  my @dates=sort (keys %{$in});
  return $dates[0];
}

sub pretty_date {
  my $date=shift or confess "I need a date here.";
  my $pretty_date=$date;
  $pretty_date=~s|-|\x{2012}|g;
  return $pretty_date;
}

sub date_to_dadi {
  my $date=shift or confess "I need a date here.";
  my $dadi=substr($date,0,4)."/$date";
  return $dadi;
}

sub dadi_to_dati {
  my $dadi=shift or confess "I need a date here.";
  my $date=substr($dadi,5);
  return $date;
}

## $in has dates as keys
sub get_latest_date_from_hash {
  my $in=shift;
  my @dates=sort (keys %{$in});
  return $dates[$#dates];
}

## $in has dates as keys
sub calculate_date_weights {
  my $in=shift;
  my $earliest=&get_earliest_date_from_hash($in);
  my $latest=&get_latest_date_from_hash($in);
  my $span=diff_dates($earliest,$latest);
  my $diffs={};
  my $total=0;
  foreach my $date (keys %{$in}) {
    if(not defined($in->{$date})) {
      next;
    }
    my $diff=&diff_dates($date,$earliest);
    $total+=$diff;
    $diffs->{$date}=$diff;
  }
  my $weights={};
  foreach my $date (keys %{$in}) {
    $weights->{$date}=$diffs->{$date}/$total;
  }
  return $weights;
}

## $in has dates as keys
sub average_by_date {
  my $in=shift;
  my $weights=&calculate_date_weights($in);
  my $average=0;
  foreach my $date (keys %{$in}) {
    $average+=$weights->{$date} * $in->{$date};
  }
  return $average;
}

sub pretty_today {
  my $time=shift // time;
  my $date=time2str("%Y\x{2012}%m\x{2012}%d", $time);
  return $date;
}

sub pretty_time {
  my $time=shift // time;
  my $date=time2str("%Y\x{2012}%m\x{2012}%d %H:%M:%S", $time);
  return $date;
}

sub get_past_dates_from_number {
  my $number=shift // '';
  my $start_date=shift // '';
  if(not $number=~m|^\d+$|) {
    confess "The first argument must be an integer.";
  }
  if($start_date) {
    if(not  $start_date=~m|^\d{4}-\d{2}-\d{2}$|) {
      confess "The argument must be a date, not '$start_date'.";
    }
  }
  else {
    $start_date=&today();
  }
  my $dates=[];
  if(not $number=~m|^\d+|) {
    confess "I need a different number than '$number'.";
  }
  ## we never look at today's date
  if(not $number > 0) {
    return $dates;
  }
  my $start=0;
  if($start_date) {
    $start=&get_time_on_date($start_date);
    ## to start from the given day
    $start+=$seconds_in_a_day;
  }
  else {
    $start=time();
  }
  my $count=0;
  while($number>0) {
    my $time=$start - $number * $seconds_in_a_day;
    $dates->[$count++]=time2str($format,$time);
    $number--;
  }
  return $dates;
}

sub today {
  my $date=time2str("%Y-%m-%d", time);
  return $date;
}

sub yesterday {
  my $yesterday=`date -I -d yesterday`;
  chomp $yesterday;
  return $yesterday;
}


sub ago_2 {
  my $ago_2=`date -I -d '2 days ago'`;
  chomp $ago_2;
  return $ago_2;
}


sub get_up_date {
  my $date=time2str("%Y\x{2012}%m\x{2012}%d", time);
  return $date;
}

sub get_update {
  my $date=time2str('%Y-%m-%d', time);
  return $date;
}

##
sub compare_dates {
  my $early=shift // confess "I need an early date here.";
  my $late=shift // confess "I need a late date here.";
  $early=~m|^(\d{4})-(\d{2})-(\d{2})| or confess "You gave me a bad date '$early'";
  my $early_time="$1$2$3";
  $late=~m|^(\d{4})-(\d{2})-(\d{2})| or confess "You gave me bad date '$late'";
  my $late_time="$1$2$3";
  if($late_time > $early_time) {
    return 1;
  }
  if($late_time < $early_time) {
    return -1;
  }
  return 0;
}


##
sub is_earlier {
  my $early=shift;
  my $late=shift;
  $early=~m|^(\d{4})-(\d{2})-(\d{2})| or confess "bad date '$early'";
  my $early_time="$1$2$3";
  $late=~m|^(\d{4})-(\d{2})-(\d{2})| or confess "bad date '$late'";
  my $late_time="$1$2$3";
  if($late_time > $early_time) {
    return 1;
  }
  return 0;
}


## later date come second
sub diff_dates {
  my $d1=shift;
  my $d2=shift;
  ## construct containing the parsed dates
  my $d;
  my $count=0;
  foreach my $in ($d1,$d2) {
    $in=~m|^(\d{4})-(\d{2})-(\d{2})| or confess "bad date '$in'.";
    $d->[$count]->[0]=$1;
    $d->[$count]->[1]=$2;
    $d->[$count]->[2]=$3;
    $count++;
  }
  if(not &Date::Calc::check_date(@{$d->[0]})) {
    # confess "The date is not $d1 is not valid.";
    return undef;
  }
  if(not &Date::Calc::check_date(@{$d->[1]})) {
    # confess "The date is not $d1 is not valid.";
    return undef;
  }
  my $delta=Date::Calc::Delta_Days(@{$d->[0]},@{$d->[1]});
  return $delta;
}

sub stretch_paper_date {
  my $in=shift // return '';
  if($in=~m|^\d{4}$|) {
    return "$in"."-01-01";
  }
  if($in=~m|^\d{4}-\d{2}$|) {
    return "$in"."-01";
  }
  if($in=~m|^\d{4}-\d{2}-\d{2}$|) {
    return "$in";
  }
  return '';
}

sub is {
  my $in=shift // confess "I need the input defined.";
  if($in=~m|^\d{4}-\d{2}-\d{2}$|) {
    return 1;
  }
  return 0;
}

sub paper_age {
  my $in=shift // return '';
  my $verbose=shift // '';
  $in=&stretch_paper_date($in) // return '';
  if($verbose) {
    print "The stretch date is $in\n";
  }
  return diff_dates($in,&today());
}

sub mshoti {
  my $file=shift // confess "I need a file here.";
  my $time=&mtime($file);
  my $shoti=&Ernad::Shoti::make($time);
  return $shoti;
}


1;
