package Cec::Bundles;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Digest;
use Digest::MD5 qw(md5);
#use File::Slurper;
#use File::Slurp;
#use JSON::XS;
use Storable qw(retrieve);

use Cec::Paths;
use Cec::Store;

my $files=$Cec::Paths::files;

## bundle index
my $bundex=$files->{'bundex'};
my $bundle_store=$files->{'r_id2n'};
my $bundex_store=$files->{'bundex_json'};
my $md5  = Digest->new("MD5");

## builds the index
sub build_index {
  my $r_list = retrieve $files->{'r_list'};
  my $count_bundle=0;
  my $bundle;
  my $i={};
  while($bundle=$r_list->[$count_bundle]) {
    $count_bundle++;
    my $b=$r_list->[$count_bundle-1];
    my $bunshid=&id($b);
    foreach my $refid(@$b) {
      if($refid eq 'lrn@handle') {
	next;
      }
      ## move to the found_in + number form
      my $map='(\d+)@([^@]+)@(\d+)+$';
      if(not $refid=~m|$map|) {
	print "I can't parse $refid\n";
	next;
      }
      my $to_index=$2.'+'.$3;
      if($i->{$to_index}) {
	#print "I see $to_index in bundle $bunshid\n";
	next;
      }
      $i->{$to_index}=$bunshid;
    }
  }
  &Cec::Store::stores($i,$bundex_store);
}

sub id {
  my $b=shift // confess "I need this defined.";
  if(not ref($b) eq 'ARRAY') {
    confess "I need an arrayref here.";
  }
  my @sorted=sort @{$b};
  my $id=join('',@sorted);
  $md5->add($id);
  my $out=$md5->b64digest();
  $out=~s|\+||g;
  $out=~s|/+||g;
  $out=substr($out,0,6);
  return $out;
}




1;
