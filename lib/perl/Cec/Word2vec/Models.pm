package Cec::Word2vec::Models;

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

sub are_line_numbers_different {
  my $file_1=shift;
  my $file_2=shift;
  my $num_1=count_lines_in_file($file_1);
  my $num_2=count_lines_in_file($file_2);
  if($num_2 eq $num_1) {
    return 0;
  }
  my $ls1=`ls -t $file_1`;
  my $ls2=`ls -t $file_2`;
  my $out="$num_1\n$ls1$num_2\n$ls2";
  return 0;
}

sub count_lines_in_file {
  my $file=shift // confess "I need a file here.";
  if(not -f $file) {
    confess "I don't see your file $file.";
  }
  my $s=`grep -c ^ $file`;
  chomp $s;
  return $s;
}

sub remove_pos {
  my $in=shift;
  my $out='';
  if(not $in) {
    return $out;
  }
  foreach my $part (split(/ /,$in)) {
    $part=~s|_[A-Z]+$||;
    $out.=' '.$part;
  }
  return $out;
}

sub make_stem_from_raw {
  my $name=shift // confess "I need a model name here.";
  my $mode=shift // confess "I need a mode here.";
  my $raw_file="$w2v_dir/$name.raw.txt";
  my $stem_file="$w2v_dir/fixes.stem.txt";
  my $out_file="$w2v_dir/$name.stem.txt";
  my $diff=&are_line_numbers_different($raw_file,$stem_file);
  if($diff) {
    warn $diff;
    return 0;
  }
  if(-f $out_file and -M $out_file < -M $stem_file and -M $out_file < -M $raw_file) {
    print "I don't renew $out_file over $stem_file and $raw_file.\n";
    return 0;
  }
  open(R,"< $raw_file");
  open(S,"< $stem_file");
  open(O,"> $out_file");
  binmode(R,'utf8');
  binmode(S,'utf8');
  binmode(O,'utf8');
  binmode(STDOUT,'utf8');
  binmode(STDERR,'utf8');
  my $in;
  while($in=<R>) {
    my $pre='';
    ## if we have a numeric mode
    if($mode=~m|^(\d+)_|) {
      my $max=$1;
      my @parts=split(/ /,$in);
      my $count=0;
      while($count++ < $max) {
	$pre.=$parts[$count-1].' ';
      }
      chop $pre;
    }
    else {
      confess "I don't know about your mode $mode";
    }
    if($mode=~m|_nopos$|) {
      my $post=<S>;
      my $line;
      if(not $post) {
	$line="$pre\n";
      }
      else {
	chomp $post;
	$post=&remove_pos($post);
	$line=$pre.$post."\n";
      }
      print O $line;
    }
    else {
      confess "I can't deal with your mode '$mode'";
    }
  }
  close R;
  close O;
  close S;
}

sub train {
  my $name=shift // confess "I need a name here.";
  my $type=shift // confess "I need a type here, raw or stem";
  my $params=shift // {};
  $params->{'binary'}=1;
  my $in_file=$dirs->{'w2v'}."/$name.$type.txt";
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

1;
