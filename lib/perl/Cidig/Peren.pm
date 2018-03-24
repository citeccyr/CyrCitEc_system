package Cidig::Peren;

## functions to deal with derived files from full text

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Temp;
use File::Slurper;
use List::Util qw(shuffle);

use Cidig::Conf;
use Cidig::Paths;
use Cidig::Files;
use Warc::File;
use Warc::Lestfi;

## warc functionalty
use Cidig::Peren::Warcs  qw (peren_dir_from_warc_dir
			     sheet2text
			     do_loud
			     report_on_missing_in_warcs
			     deal_with_warcs
			     warc2text);
## ParsCit functionalty
#use Cidig::Peren::ParsCit qw (parscit_texts
#			      text2parscit);
### FindCit functionalty
#use Cidig::Peren::FindCit  qw (findcit_texts
#			       text2findcit);

## a single method that will do pretty much everything and returns a configuration
sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $p={};
  bless $p, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $p->{$key}=$params->{$key};
  }
  #$p->{'file_style'};
  ## use $v to be the verbose setting
  my $verbose=$p->{'verbose'};
  #$p->{'conf'}=Cidig::Conf->get({'verbose'=>$verbose});
  $p->{'conf'}=Cidig::Conf->get();
  my $conf=$p->{'conf'}->{'_'};
  if($conf->{'peren_dir'}) {
    $p->{'peren_dir'}=$conf->{'peren_dir'};
    ## better
    $p->{'dir'}->{'peren'}=$conf->{'peren_dir'};
  }
  if($conf->{'warc_dir'}) {
    $p->{'warc_dir'}=$conf->{'warc_dir'};
    ## better
    $p->{'dir'}->{'warc'}=$conf->{'warc_dir'};
  }
  if($conf->{'cache_dir'}) {
    $p->{'cache_dir'}=$conf->{'cache_dir'};
    ## better
    $p->{'dir'}->{'cache'}=$conf->{'cache_dir'};
  }
  $p->check_input();
  ## converter data
  $p->{'converters'}=['poppler','pdfminer','pdf-stream'];
  foreach my $converter (@{$p->{'converters'}}) {
    $p->{'converter'}->{$converter}=1;
    my $run_it=$Cidig::Paths::bin->{$converter} // confess "I need this defined.";
    if(not -f $run_it) {
      confess "I don't see your converter $run_it.";
    }
    $p->{'bin'}->{$converter}=$run_it;
    ## mark it in a hash
    $p->{'converter'}->{$converter}=1;
  }
  return $p;
}

## run a scommand on a spcifc inptu
sub run {
  my $p=shift;
  my $com=shift // confess "I need a command here";
  my $in=shift // confess "I need an 'in' part here.";
  my $out=shift // confess "I need an 'out' part here.";

}
sub apply {
  my $p=shift;
  my $com=shift // confess "I need a command here";
  my $in=shift // confess "I need an 'in' part here.";
  my $out=shift // confess "I need an 'out' part here.";
  ## an optional coverter to add an argument
  my $arg_convert = shift // '';
  ## the script part
  my $script;
  if(index($com,' ') == -1) {
    $script=$com;
  }
  else {
    $script=substr($com,0,(index($com,' ')));
  }
  if(not -f $script) {
    confess "I don't see your script '$script'.";
  }
  $|=1;
  print "I load file ... ";
  my $files=$p->load_files('');
  print " done\n";
  foreach my $file (@$files) {
    if(not $file=~m|$in|) {
      next;
    }
    my $out_file=$file;
    $out_file=~s|$in|$out|;
    if(not $p->{'force'} and
       not &Cidig::Files::does_file_need_renewal($out_file,$file,$script)) {
      next;
    }
    my $err="$out_file.err";
    my $s;
    if(not $arg_convert) {
      $s="$com $file > $out_file 2> $err";
    }
    else {
      my $handle=&{$arg_convert}($file);
      $s="$com $file $handle > $out_file 2> $err";
    }
    if($p->{'verbose'}) {
      print "I run '$s' ...";
    }
    system($s);
    if(not -z $err) {
      my $err_text=&File::Slurper::read_text($err);
      warn "\n\nrecitex ended with an error\n '$err_text'.";
    }
    if($p->{'verbose'}) {
      print " done\n"
    }
    if(-z $out_file) {
      confess "Your out_file $out_file is empty.";
    }
    if($p->{'run_strict'}) {
      if(-s $err) {
	my $out=`cat $err`;
	$out=~s|\S+$||;
	confess $out;
      }
    }
  }
}

## do we need this?
sub check_input {
  my $p=shift;
#  if(not $p->{'input'} or (not ($p->{'input'} eq 'warc' or
#				$p->{'input'} eq 'pdfs'))) {
#    confess "You need the set the input  to 'warcs' or 'pdfs'.";
#  }
#  ## if the input is warc_dir, we also need the peren dir defined
#  if($p->{'input'} eq 'warc') {
#    if(not defined($p->{'peren_dir'})) {
#      confess "You need the set the peren_dir.";
#    }
#    if(not defined($p->{'warc_dir'})) {
#      confess "You need the set the warc_dir.";
#    }
#  }
}

sub load_files {
  my $p=shift;
  ## the type can be empty
  my $type=shift // confess "I need a type here.";
  my $files;
  ## is it ok to load from the cache
  my $load_type;
  if(not $type) {
    $load_type='dodir';
  }
  else {
    $load_type=$type;
  }
  if($p->{'cache_ok'}) {
    $files=&Cidig::Files::load_from_cache($p->{'dir'}->{'cache'},$load_type);
    return $files;
  }
  ## by default, load by running a file::find
  if(not $load_type eq 'dodir') {
    $load_type=$type;
  }
  ## this will only work if the type is not empty
  if($type) {
    $load_type.='$';
    $load_type=~s|\.|\\.|g;
  }
  $files=&Cidig::Files::load_from_directory($p->{'dir'}->{'peren'},$type);
  return $files;
}

sub load_dodir {
  my $p=shift;
  if($p->{'cache_ok'}) {
    $p->{'dodir'}=&Cidig::Files::load_from_cache($p->{'dir'}->{'cache'},'dodir');
    return $p->{'dodir'};
  }
  my $files=$p->load_files($p->{'dir'}->{'peren'},'');
  $p->{'dodir'}={};
  foreach my $fufi (@$files) {
    ## don't consider directories of documents
    if(-d $fufi) {
      next;
    }
    my $dirname=&dirname($fufi);
    $p->{'dodir'}->{$dirname}=1;
  }
  return $p->{'dodir'};
}

sub i_need_new {
  my $p=shift;
  my $fufi=shift // confess "I need a file here";
  if(not -f $fufi) {
    return 1;
  }
  ## no renewal if not set
  if(not $p->{'force_renew'}) {
    return 0;
  }
  ## force renwewal is less or 1
  if($p->{'force_renew'} <= 1) {
    return 1;
  }
  my $max_age=$p->{'force_renewal'}-1;
  ## in case greater than 1
  my $age=-M $fufi;
  if($age > $max_age) {
    return 1;
  }
  confess "FixMe: I should not be on this line.";
}

sub find_finus {
  my $p=shift;
  my $dodir=shift // confess "I need dodir argument here.";
  if(not -d $dodir) {
    confess "I can't see your dodir $dodir";
  }
  my @finus;
  ## a hash to keep track of repetitions
  my $finu_is_there;
  ## find finu parts of files
  foreach my $file (`ls $dodir/*.xml`) {
    chomp $file;
    my $bana=basename($file);
    ## finu part must start with a number
    if(not $bana=~m|^(\d+)|) {
      warn "I see a foreign file $file.";
      next;
    }
    my $finu=$1;
    if(not $finu_is_there->{$finu}) {
      push (@finus,$1);
      $finu_is_there->{$finu}=1;
    }
  }
  return @finus;
}


sub test_dodir {
  my $p=shift;
  my $dodir=shift // confess "I need a dodir defined here.";
  ## make it easy. check if it's a relavite
  my $peren_dir=$p->{'dir'}->{'peren'};
  if(-d "$peren_dir/$dodir") {
    $dodir="$peren_dir/$dodir";
  }
  if(not -d $dodir) {
    print "I can't see $dodir\n";
    exit;
  }
  ## remove a trailing /
  if(substr($dodir,length($dodir)-1) eq '/') {
    chop $dodir;
  }
  ## not uses in cec projec
#  foreach my $file (`ls $dodir/*.txt`) {
#    chomp $file;
#    if(not ($file=~m|\.poppler\.txt$| or $file=~m|\.pdfminer\.txt$|)) {
#      next;
#    }
#    $p->text2findcit($file);
#    $p->text2parscit($file);
#  }
#  my @finus=$p->find_finus($dodir);
#  foreach my $finu (@finus) {
#    ## first case
#    foreach my $converter (@{$p->{'converters'}}) {
#      my $fc="$dodir/$finu.$converter.findcit.xml";
#      my $pc="$dodir/$finu.$converter.parscit.xml";
#      if(-f $fc and (not -f $pc)) {
#	print "I have $fc\n but not\n$pc\n";
#	## check if this is the "bad data issue"
#	if(-f "$pc.err") {
#	  my $txt=&File::Slurper::read_text("$pc.err");
#	  if($txt=~m|^Bad data |) {
#	    print "It's the 'Bad data' issue, harmless\n";
#	  }
#	}
#	else {
#	  exit;
#	}
#      }
#      if(-f $pc and (not -f $fc)) {
#	print "I have $pc\n but not\n$fc\n";
#	exit;
#      }
#      ## they may not be both there because of the bad data problem,
#      ## and then the diff failss
#      if(not (-f $pc and -f $fc)) {
#	## we don't do more for this converter
#	next;
#      }
#      my $s="diff $pc $fc";
#      my $diff=`$s`;
#      if(not $diff) {
#	## we don't do more for this converter
#	next;
#      }
#      print "$diff";
#      print "dodir $dodir fails\n";
#      exit;
#    }
# }
  return 1;
}

sub prep_file_list {
  my $p=shift;
  my $type=shift // confess "I need a type here.";
  my $tmp_file="/tmp/$type.list";
   if(-f $tmp_file and (-M $tmp_file < 1)) {
    return $tmp_file;
  }
  ## from the config
  my $dirs=$Cec::Paths::dirs;
  my $peren_dir=$dirs->{'peren'} // confess "I don't see your peren dirictory.";
  ## directories already found
  $dirs={};
  #print "new";
  open(T,"> $tmp_file");
  ## note the dot in the search glob here
  my $to_find="find $peren_dir -type f -name '*.$type'";
  foreach my $file (`$to_find`) {
    my $dir=dirname($file);
    if($dirs->{$dir}) {
      next;
    }
    $dirs->{$dir}=1;
    print T $dir,"\n";
  }
  close T;
  return $tmp_file;
}

sub peren_dir_to_warc {
  my $p=shift;
  my $dir=shift;
  if(not $dir) {
    confess "I need a directory here.";
  }
  if(not -d $dir) {
    confess "I need a directory here, but you gave me '$dir'.";
  }
  my $warc_dir=$p->{'dir'}->{'warc'} // confess "I need a warc dir here.";
  my $peren_dir=$p->{'dir'}->{'peren'} // confess "I need a peren dir here.";
  my $warc_file=$warc_dir.substr($dir,length($peren_dir)).'.warc';
  return $warc_file;
}



1;
