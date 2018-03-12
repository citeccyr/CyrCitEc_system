package Cec::Xslt;

use strict;
use warnings;

use Carp qw(confess);
use XML::LibXSLT;
use XML::LibXML;

use Cec::Paths;

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


1;
