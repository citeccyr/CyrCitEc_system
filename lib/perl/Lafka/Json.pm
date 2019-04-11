package Lafka::Json;

use strict;
use warnings;

use Carp qw(confess);
use File::Slurp;
# use File::Slurper;
use JSON::XS;

sub load {
  my $file=shift;
  # print "I read $file\n";
  my $json=&File::Slurp::read_file($file);
  # my $json=&File::Slurper::read_text($file);
  my $data;
  eval {
    $data=decode_json($json);
  };
  if($@) {
    confess "I can't read $file as Json";
  }
  return $data;
}

## dumps json
sub save {
  my $data=shift;
  my $file=shift;
  if(not ref($data)) {
    confess "I can't encode $data";
  }
  #my $json=encode_json($data);
  my $json=JSON::XS->new->pretty(1)->encode($data);
  # &File::Slurper::write_text($file,$json);
  &File::Slurp::write_file($file,$json);
  return 1;
}

1;
