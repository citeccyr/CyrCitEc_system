package Cec::Word2vec::Base;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Basename;
use Getopt::Std;
use List::Util qw(shuffle);
use IO::File;

use Cec::Paths;
use Cec::Xslt;

my $dirs=$Cec::Paths::dirs;
my $files=$Cec::Paths::files;
my $warc_dir=$dirs->{'warc'};
my $w2v_dir=$dirs->{'w2v'};
my $peren_dir=$dirs->{'peren'};
my $w2v_bin=$files->{'w2v_bin'};

my $raw_file="$w2v_dir/raw.txt";
my $fixes_model="$w2v_dir/raw.model";
my $fixes_model_tmp="$w2v_dir/fixes.model.tmp";

my $defaults;
$defaults->{'size'}=100;
$defaults->{'window'}=5;
$defaults->{'sample'}='1e-3';
$defaults->{'hs'}=0;
$defaults->{'negative'}=5;
$defaults->{'threads'}=12;
$defaults->{'iter'}=5;
$defaults->{'min-count'}=5;
$defaults->{'alpha'}=.05;
$defaults->{'classes'}=0;
$defaults->{'debug'}=2;
## this is not the default for the package, but without it
## we don't seem to be able to get any results
$defaults->{'binary'}=0;
## we do both cbow and skip-gram
# $defaults->{'cbow'}=1;

## files
my $f;

#sub raw_input {
#  my $transformer=shift // confess "I need a tranformer here.";
#  my $out_file="$w2v_dir/$transformer"."_raw.txt";
#  open(F,"> $out_file");
#  binmode(F,'utf8');
#  my @founds=`find $peren_dir -type f -name 'summary.xml'`;
#  foreach my $found (shuffle @founds) {
#    chomp $found;
#    if(&is_it_excluded($found)) {
#      next;
#    }
#    else {
#    }
#    my $fixes=&Cec::Xslt::transform($found,$transformer)->textContent() // next;
#    print F $fixes;
#  }
#  close F;
#}

sub get_harvesters {
  my $h;
  my $xslt_dir=$dirs->{'xslt'};
  foreach my $file (`ls $xslt_dir/*.harvest.xslt.xml`) {
    chomp $file;
    my $name=basename($file);
    $name=~s|\.xslt\.xml||;
    my $sheet=&Cec::Xslt::get_sheet($name);
    $name=~s|\.harvest||;
    $h->{$name}=$sheet;
  }
  return $h;
}

sub open_files {
  my $h=shift;
  my $type=shift // 'raw';
  ## a hash of files
  my $f;
  foreach my $name (keys %$h) {
    my $file=$dirs->{'w2v'}."/$name.$type.txt";
    my $fh=IO::File->new("> $file");
    binmode($fh,'utf8');
    $f->{$name}=$fh;
  }
  return $f;
}

sub raw_input_harvest {
  my $type=shift // 'raw';
  ## a hash of transformers
  my $h=&get_harvesters();
  my $f=&open_files($h,$type);
  my @founds=`find $peren_dir -type f -name 'summary.xml'`;
  foreach my $found (shuffle @founds) {
    chomp $found;
    if(&is_it_excluded($found)) {
      next;
    }
    foreach my $name (keys %$h) {
      my $transformer=$h->{$name};
      my $line=&Cec::Xslt::transform($found,$transformer)->textContent() // next;
      my $fh=$f->{$name};
      print $fh $line;
    }
  }
}

sub python {
  my $in=shift // confess "I need an input here.";
  my $name=shift // confess "I need a name here.";
  my $exec=$dirs->{'python'}.'/'.$name;
  if(not -f $exec) {
    confess "I don't see your file $exec";
  }
  ## check if we already have a new version
  my $out_file="$w2v_dir/$in"."_$name.txt";
  my $raw_file="$w2v_dir/$in"."_raw.txt";
  if(-z $out_file) {
    unlink $out_file;
  }
  elsif(-f $out_file and (-M $out_file < -M $raw_file)) {
    print "I don't renew $out_file over $raw_file.\n";
    return 0;
  }
  my $s="$exec $in";
  print "$s\n";
  system($s);
}

sub train {
  my $name=shift // confess "I need a name here.";
  my $type=shift // confess "I need a type here, raw or stem";
  my $params=shift // {};
  $params->{'binary'}=1;
  my $in_file=$dirs->{'w2v'}."/$name"."_$type.txt";
  if(not -f $in_file) {
    warn "I don't see your in_file $in_file.";
    return 0;
  }
  my $cmd='';
  foreach my $key (keys %$params) {
    if(not defined($defaults->{$key})) {
      die "I don't know about your parameter $key.";
    }
    if($defaults->{$key} ne $params->{$key}) {
      $cmd.=" -$key ".$params->{$key};
    }
  }
  foreach my $orient ('cbow','skig') {
    my $cbow=0;
    if($type eq 'cbow') {
      $cbow=1;
    }
    my $base="$name.$type.$orient";
    ## default is non-binary
    my $out_file=$dirs->{'w2v'}."/$base.model";
    my $bin_file=$dirs->{'w2v'}."/$base.bin";
    if(-z $out_file) {
      unlink $out_file;
    }
    elsif(-f $out_file and -M $out_file < -M $in_file) {
      print "I don't renew $out_file over $in_file\n";
      return 0;
    }
    my $log=$dirs->{'w2v'}."/$base.log";
    my $err=$dirs->{'w2v'}."/$base.err";
    my $s="$w2v_bin -train $in_file -cbow $cbow -output $bin_file $cmd";
    $s.=" > $log 2> $err";
    print "$s\n";
    system("$s");
    $s="gzip -fc $bin_file > $bin_file.gz";
    print "$s\n";
    system("$s");
  }
}

sub is_it_excluded {
  my $file=shift;
  foreach my $series ('RePEc/bkr/wpaper',
		      'RePEc/cfr/cefirw',
		      'RePEc/eus/ce3swp',
		      'RePEc/gai/ppaper',
		      'RePEc/hig/fsight',
		      'RePEc/hig/wpaper') {
    if($file=~m|/$series/|) {
      #print "I exclude $file\n";
      return 1;
    }
  }
  return 0;
}

1;
