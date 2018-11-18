package Cec::Meta;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use URI::Escape;
use File::Basename;
#use File::Slurper;
#use File::Slurp;
#use JSON::XS;
use Cec::Paths;

my $dirs=$Cec::Paths::dirs;

use Cidig::Ris;

sub file {
  my $found_in=shift;
  my $peren=&{$Cidig::Ris::id2file->{'spz'}}($found_in);
  my $path=uri_unescape($peren);
  ## remove first part
  $path=~s|^[^/]+/||;
  #print "$path\n";
  my $file=$dirs->{'input'}.'/'."$path.xml";
  if(-f $file) {
    return $file;
  }
  ## second attempt
  my $dir=dirname($file);
  ## sometimmes is the archive and series added to the file name
  my $series=basename($dir);
  $dir=dirname($dir);
  my $archive=basename($dir);
  my $bana="$archive$series".basename($file);
  my $second_file=dirname($file).'/'.$bana;
  if(-f $second_file) {
    return $second_file;
  }
  if(dirname($file) eq '/home/cec/var/opt/input/rus/ipmpnt') {
    my $file=dirname($file).'/p'.basename($file);
    if(-f $file) {
      return $file;
    }
    warn "I tried '$file'.";
  }
  my $badbase='/home/cec/var/opt/input/hig/wpaper/';
  if($file=~m|$badbase|) {
    my $end=$file;
    $end=~s|$badbase||;
    $end=~s|/|-|g;
    my $file=$badbase."/higwpaper$end";
    if(-f $file) {
      return $file;
    }
    warn "I tried '$file'.";
  }
  warn "I don't see meta_file '$file' from '$found_in'.";
  return '';
}

1;
