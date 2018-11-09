package Cec::Xslt;

use strict;
use warnings;

use Carp qw(confess);
use XML::LibXSLT;
use XML::LibXML;

use Cec::Paths;

## a collections of sheets
my $x;

sub get_sheet {
  my $name=shift;
  my $xslt = XML::LibXSLT->new();
  my $xslt_file=$Cec::Paths::dirs->{'xslt'}."/$name.xslt.xml";
  if(not -f $xslt_file) {
    confess "I can't open your file $xslt_file.";
  }
  my $style_doc = XML::LibXML->load_xml(location=>$xslt_file,  no_cdata=>1);
  my $sheet= $xslt->parse_stylesheet($style_doc);
  return $sheet;
}

sub transform {
  my $in=shift;
  my $name=shift;
  my $params=shift;
  if(not ref($in)) {
    my $file=$in;
    if(not -f $file) {
      confess "I can't see your file $file.";
    }
    if(-z $file) {
      unlink $file;
      return;
    }
    eval {
      $in = XML::LibXML->load_xml(location=>$file,  no_cdata=>1);
    };
    if($@) {
      print "$file $@\n";
      unlink $file;
      return undef;
    }
  }
  my $result;
  ## if name is just a name
  if(not ref($name)) {
    if(not $x->{$name}) {
      $x->{$name}=&get_sheet($name);
    }
    $result=$x->{$name}->transform($in,%$params);
  }
  elsif(ref($name) eq 'XML::LibXSLT::StylesheetWrapper') {
    $result=$name->transform($in);
  }
  else {
    confess "I don't know about" . ref($name);
  }
  #return $x->{$name}->output_as_bytes($result);
  return $result;
}

1;
