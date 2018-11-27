#!/usr/bin/perl
use strict;
use warnings;

use Cec::Paths;
use File::Slurper qw(read_text);
use JSON::XS;
use lib '../Modules'; # no need from web request

use MyXMLParser;
#use LWP::Simple;
use Data::Dumper;
use Cyrcitec;
#use GT::Template;
#use Template;
use CGI;
use URI::Escape;
use Encode;
use BundleXml;

#my $files=$Cec::Paths::files;
my $dirs=$Cec::Paths::dirs;
my $que = new CGI();
 

print "Content-type: text/html; charset=utf-8\n\n";
print get_dif();

sub get_dif
{
  my $code = $que->param('code');
  my $json = &File::Slurper::read_text($dirs->{'www_w2v'}.'/internal_clusters.json');
  my $jdata = JSON::XS->new->decode ($json);
  my $hs = $jdata->{$code};

  my $bndl = new BundleXml($code);

  foreach my $num (keys %{$hs->{'internal_clusters'}}) {
      #print Dumper( $hs->{'internal_clusters'}->{$num} );
      foreach my $ln (@{$hs->{'internal_clusters'}->{$num}->{'lines'}})  {
        my @arr = split ' ', $ln;
	#print $arr[1]."\n";
        my $x = $bndl->GetIntextRef($arr[1], $arr[2], $arr[3]);  #  'spz:neicon:vair-journal:y:2018:i:3:p:5-13', '11',  '2062'
        push @{$hs->{'internal_clusters'}->{$num}->{'lines_ref'}}, $x;
	#print Dumper($x); exit;
      }
  }
  Cyrcitec::parseTemplate('dif.html', { title => $bndl->GetTitle(), clusters => $hs->{'internal_clusters'}, avg => round(1000*$hs->{'average_to_clustroid'}) } );
}

sub round { my $float=$_[0]; return int($float + $float/abs($float*2 || 1)); }


