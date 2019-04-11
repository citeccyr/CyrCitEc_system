#!/usr/bin/perl

use strict;

use lib '../Modules';
use Data::Dumper;
use CGI;
use BundleXml;
use BundleConfig;
use Cec::Paths;

my $files=$Cec::Paths::files;
my $dirs=$Cec::Paths::dirs;


print "Content-type: text/html; charset=utf-8\n\n";
my $que = new CGI;
my $code = $que->param('code');
my $type = $que->param('type') || 'analysis';  # repec_bundles  bundles
my $c = $que->param('c');

my $dir = $c ? BundleConfig->new($c)->{'bundles_xml'} : $dirs->{$type.'_xml'};


#if($ty) {
  my $b = BundleXml->new($code, {'dir_xml' => $dir });
#  print $b->test();
#  print '---';
#exit;
#}

#Cyrcitec::parseTemplate('main.html', { root => BundleXml->new->GetHashExt($code) } );
Cyrcitec::parseTemplate('main.html', { root => $b->GetHashExt() } );

