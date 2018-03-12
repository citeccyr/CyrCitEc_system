package Lafka::Exclude;

## a module to decide whether a download is excluded.
## at this time, we only have an exclusion by id

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Slurper;

#use Lafka::Common;
use Cidig::Conf;
use Lafka::Paths;
#use Lafka::Ris;
#use Lafka::Warcs;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $e={};
  bless $e, $class;
  ## get Lafka variables
  $e->{'file'}=$Lafka::Paths::file;
  $e->{'dir'}=$Lafka::Paths::dir;
  $e->{'conf'}=Cidig::Conf->get({'conf'=>'lafka'});
  ## copy parameters into the structure
  my $params=shift;
  foreach my $key (keys %{$params}) {
    $e->{$key}=$params->{$key};
  }
  $e->get();
  return $e;
}

sub get {
  my $e=shift;
  my $file=$e->{'conf'}->{'exclude_file'};
  $e->{'regx'}={};
  if(not $file or not -f $file) {
    return 0;
  }
  my @lines=File::Slurper::read_lines($file);
  foreach my $line (@lines) {
    my @parts=split(' ',$line);
    my $regx=$parts[0];
    $e->{'regx'}->{$regx}=1;
  }
  return 1;
}

sub is_excluded_by_id {
  my $e=shift;
  my $id=shift;
  foreach my $regx (keys %{$e->{'regx'}}) {
    if($id=~m|$regx|) {
      return 1;
    }
  }
  return 0;
}

1;
