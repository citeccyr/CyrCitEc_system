package Warc::Checks;

use strict;
use warnings;

use Carp qw(confess);
#use Data::Dumper;
#use Date::Parse;
#use IO::File;

#use Warc::Constants;
#use Warc::Record;
#use Warc::Warcinfo;

our $c;

## https://stackoverflow.com/questions/3728585/how-to-recognize-pdf-format
$c->{'application/pdf'}=sub {
  my $in=shift;
  my $verbose=1;
  my $start=substr($in,0,4069);
  my $pdf_mark_pos=&pdf_mark_pos($start);
  if($pdf_mark_pos == -1) {
    return 0;
  }
  ## it has the pdf_mark
  my $has_pdf_mark=1;
  my $piece=substr($start,$pdf_mark_pos,20);
  ## nomalize the piece
  $piece=~s|\n||g;
  $piece=~s|\r||g;
  my $higher=substr($piece,9,4);
  ## check if off these have an ord over 128
  my $count=0;
  my $has_inferior_char=0;
  while($count<4) {
    my $char=substr($higher,$count,1);
    if(ord($char)<128) {
      if($has_pdf_mark) {
	$has_inferior_char=1;
      }
    }
    $count++;
  }
  if(not $has_inferior_char) {
    return 1;
  }
  ## check out the end
  my $end=substr($in,-10);
  $end=~s|\s||g;
  if($end=~m|%%EOF$|) {
    return 1;
  }
  confess "a pdf_mark with no PDF";
  return 0;
};

sub pdf_mark_pos {
  my $in=shift;
  my @vns=('2.0','1.7','1.6','1.5','1.4','1.3','1.2','1.1','1.0');
  foreach my $vn (@vns) {
    my $pdf_mark='%'.'PDF-'.$vn;
    #print "pdf_mark $pdf_mark\n";
    my $pos=index($in,$pdf_mark);
    if($pos>-1) {
      return $pos;
    }
  }
  return -1;
}

1;
