package Cec::Xml;
use strict;
use warnings;

use Carp qw(confess);
use Encode;
use File::Basename;
use File::Copy;
use File::Path;
use File::Temp;
use Text::Diff;
use XML::LibXML;


sub install_doc  {
  my $doc=shift;
  my $out_file=shift;
  my $debug=0;
  ###
  #$debug=1;
  if($debug) {
    $|=1;
    binmode(STDOUT,"utf8");
  }
  ###
  if(not ref($doc) eq 'XML::LibXML::Document') {
    confess "I need a document here.";
  }
  if(not -f $out_file) {
    my $dir=dirname($out_file);
    if(not -d $dir) {
      mkpath $dir;
    }
    if($debug) {
      print "I installed $out_file\n";
    }
    $doc->toFile($out_file,1);
    return 1;
  }
  my $string=$doc->toString(1);
  my $len=length($string);
  my $diff;
  if(length($string) < 10000) {
    if($debug) {
      print "I start the internal diff on $len ..."
    }
    $diff= diff $out_file, \$string,  { STYLE => "OldStyle" };
    if($debug) {
      print " done\n";
    }
    if(not $diff) {
      if($debug) {
	print "$out_file is unchanged.\n";
      }
      return 0;
    }
    $diff=decode('UTF-8', $diff);
    my $len_diff=length($diff);
    my $dareg="\\d{4}\\x{2012}\\d{2}\\x{2012}\\d{2}";
    if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s+$dareg\.\s*$|) {
      if($debug) {
	print "I keep old version of $out_file\n";
	if($len_diff < 100) {
	  print "$diff\n";
	}
	else {
	  print "I DONT PRINT a diff of $len_diff\n";
	}
      }
      return 0;
    }
  }
  else {
    if($debug) {
      print "I start the external diff on $len ..."
    }
    my $fh = File::Temp->new();
    my $tmp_file = $fh->filename;
    $doc->toFile($tmp_file,1);
    $diff=`diff -w $tmp_file $out_file`;
    chomp $diff;
    if(not $diff) {
      if($debug) {
	print "$out_file is unchanged.\n";
      }
      return 0;
    }
    ## fixMe: the \\D+ should be \\x{2012}.
    my $dareg="\\d{4}\\D+\\d{2}\\D+\\d{2}";
    #  if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s*$dareg\.\s*$|) {
    if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s+$dareg\.\s*$|) {
      if($debug) {
	print "I keep old version of $out_file\n";
      }
      return 0;
    }
    ## we install the doc, rather than use the tmp_file
  }
  if($debug) {
    my $len_diff = length($diff);
    if($len_diff < 100) {
      print "$diff\n";
    }
    else {
      print "I DONT PRINT a diff of $len_diff\n";
    }
  }

  if($debug) {
    print "I install a new version of $out_file\n";
  }
  $doc->toFile($out_file,1);
  return 1;
}

sub install_doc_with_internal_diff  {
  my $doc=shift;
  my $out_file=shift;
  my $debug=0;
  ###
  $debug=1;
  if($debug) {
    binmode(STDOUT,"utf8");
  }
  ###
  if(not ref($doc) eq 'XML::LibXML::Document') {
    confess "I need a document here.";
  }
  if(not -f $out_file) {
    my $dir=dirname($out_file);
    if(not -d $dir) {
      mkpath $dir;
    }
    if($debug) {
      print "I installed $out_file\n";
    }
    $doc->toFile($out_file,1);
    return 1;
  }
  my $string=$doc->toString(1);
  my $len=length($string);
  if($debug) {
    print "I start the diff on $len ..."
  }
  my $diff= diff $out_file, \$string,  { STYLE => "OldStyle" };
  if($debug) {
    print " done\n";
  }
  if(not $diff) {
    if($debug) {
      print "$out_file is unchanged.\n";
    }
    return 0;
  }
  $diff=decode('UTF-8', $diff);
  my $len_diff=length($diff);
  my $dareg="\\d{4}\\x{2012}\\d{2}\\x{2012}\\d{2}";
  if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s+$dareg\.\s*$|) {
    if($debug) {
      print "I keep old version of $out_file\n";
      if($len_diff < 100) {
	print "$diff\n";
      }
      else {
	print "I DONT PRINT a diff of $len_diff\n";
      }
    }
    return 0;
  }
  if($debug) {
    print "I install a new version of $out_file\n";
    if($len_diff < 100) {
      print "$diff\n";
    }
    else {
      print "I DONT PRINT a diff of $len_diff\n";
    }
  }
  $doc->toFile($out_file,1);
  return 1;
}

sub install_doc_with_external_diff {
  my $doc=shift;
  my $out_file=shift;
  my $debug='';
  if(not ref($doc) eq 'XML::LibXML::Document') {
    confess "I need a document here.";
  }
  if(not -f $out_file) {
    my $dir=dirname($out_file);
    if(not -d $dir) {
      mkpath $dir;
    }
    if($debug) {
      print "I installed $out_file\n";
    }
    $doc->toFile($out_file,1);
    return 1;
  }
  my $fh = File::Temp->new();
  my $tmp_file = $fh->filename;
  $doc->toFile($tmp_file,1);
  my $diff=`diff -w $tmp_file $out_file`;
  chomp $diff;
  if(not $diff) {
    if($debug) {
      print "$out_file is unchanged.\n";
    }
    return 0;
  }
  ## fixMe: the \\D+ should be \\x{2012}.
  my $dareg="\\d{4}\\D+\\d{2}\\D+\\d{2}";
  #  if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s*$dareg\.\s*$|) {
  if($diff=~m|^\d+c\d+\s*[<>]\s*$dareg\.\s*---\s*[<>]\s+$dareg\.\s*$|) {
    if($debug) {
      print "I keep old version of $out_file\n";
    }
    return 0;
  }
  if($debug) {
    print "I install a new version of $out_file\n$diff\n";
  }
  copy($tmp_file,$out_file);
}

1;
