package Cec::Store;

use strict;
use warnings;

## в79в7304в

use Carp qw(confess);
use Data::Dumper;
use File::Slurper;
use File::Slurp;
use JSON::XS;


## loads json
#sub load {
#  my $file=shift;
#  my $data={};
#  if(not -f $file) {
#    return {};
#  }
#  my $json=&File::Slurper::read_text($file);
#  $data=decode_json($json);
#  return $data;
#}

## loads json with Slurp
sub load {
  my $file=shift;
  my $data={};
  if(not -f $file) {
    return {};
  }
  my $json=&File::Slurp::read_file($file);
  $data=decode_json($json);
  return $data;
}

## dumps json
sub store {
  my $data=shift;
  my $file=shift;
  if(not $data) {
    confess "I don't have data to save";
  }
  my $json=encode_json($data);
  &File::Slurper::write_text($file,$json);
  return 1;
}

## dumps json
sub stores {
  my $data=shift;
  my $file=shift;
  if(not $data) {
    confess "I don't have data to save";
  }
  my $json=encode_json($data);
  &File::Slurp::write_file($file,$json);
  return 1;
}

sub hash_from_lines {
  my $file=shift;
  my $o={};
  if(-f $file) {
    my @lines=&File::Slurper::read_lines($file);
    foreach my $line (@lines) {
      chomp $line;
      $line=~s|\s||g;
      if($line) {
	$o->{$line}=1;
      }
    }
  }
  return $o;
}




1;
