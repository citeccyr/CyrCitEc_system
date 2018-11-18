package Cec::Recitex;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
#use File::Slurper;
#use File::Slurp;
#use JSON::XS;

use Cec::Paths;

my $dirs=$Cec::Paths::dirs;

use Cidig::Ris;

sub file {
  my $found_in=shift;
  my $peren=&{$Cidig::Ris::id2file->{'spz'}}($found_in);
  my $file=$dirs->{'peren'}.'/'.$peren.'/summary.xml';
  if(not -f $file) {
    print "I can't find cite_file '$file' from '$found_in'.";
    return '';
  }
  return $file;
}

sub reference_by {
  my $found_in=shift // confess "I need the found_in here.";
  my $number=shift // confess "I need a number here.";
  my $what=shift // confess "I need to know by what you want to find";
  if(not $number=~m|^\d+$|) {
    confess "I have an issue with your number '$number'";
  }
  if(not ($what eq 'num' or $what eq 'start')) {
    confess "\$what has to be 'num' or 'start'";
  }
  my $in_doc=$found_in;
  if(not ref($in_doc) eq 'XML::LibXML::Document') {
    my $file=&file($found_in) or return 0;
    $in_doc = XML::LibXML->load_xml(location => $file);
  }
  #print $in_doc;
  my $ref_xp='//reference[@'."$what='$number']";
  my $found_ref_ele=$main::xpc->find($ref_xp,$in_doc)->[0];
  if(not $found_ref_ele) {
    #print "No $ref_xp in $file.\n";
    return 0;
  }
  #my $futli_eles=$main::xpc->find("../../../../..",$found_ref_ele);
  #if(not $futli_eles) {
  #  #print "I don't see an element futli in $file\n";
  #  next;
  #}
  #my $futli_ele=$futli_eles->[0];
  #if(not $futli_ele->nodeName eq 'futli') {
  #  #warn "I don't see an element futli in $file\n";
  #}
  #my $futli_url=$futli_ele->getAttribute('url') // '';
  #$ref_ele->appendChild($found_ref_ele->cloneNode(1));
  #if($futli_url) {
  #  $ref_ele->setAttribute('futli',$futli_url);
  #}
  #$ref_ele->appendText("\n");
  #
  #
  ## no cloneNode here!
  return $found_ref_ele;
}


1;
