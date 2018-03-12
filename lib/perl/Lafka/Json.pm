package Lafka::Json;

use strict;
use warnings;

use File::Slurp;
# use File::Slurper;
use JSON::XS;

sub load {
  my $file=shift;
  # print "I read $file\n";
  my $json=&File::Slurp::read_file($file);
  # my $json=&File::Slurper::read_text($file);
  my $data=decode_json($json);
  return $data;
}

## dumps json
sub save {
  my $data=shift;
  my $file=shift;
  my $json=encode_json($data);
  # &File::Slurper::write_text($file,$json);
  &File::Slurp::write_file($file,$json);
  return 1;
}

1;
