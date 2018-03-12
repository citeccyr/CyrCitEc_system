package Warc::Warcinfo;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Date::Parse;
use IO::File;

use Warc::Constants;

## a library to parse the contents of the warcinfo record

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $i={};
  bless $i, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $i->{$key}=$params->{$key};
  }
  if(not $i->{'body'}) {
    confess "I need your body.";
  }
  return $i;
}

## parse the contents
sub parse {
  my $i=shift;
  my $search=$Warc::Constants::header_search // confess "I need this defined here.";
  my $body=$i->{'body'} // confess "I need your body.";
  my @lines=split(/\r\n/,$body);
  foreach my $line (@lines) {
    if($line=~m|$search|) {
      my $name=$1;
      my $value=$2;
      $value=~s|^\s+||;
      $value=~s|\s+$||;
      $i->{'info'}->{$name}=$value;
      push(@{$i->{'infos'}},{$name => $value});
    }
  }
  delete $i->{'body'};
}

1;
