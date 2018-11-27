#!/usr/bin/perl

use strict;

use lib '../Modules';
use Data::Dumper;
use CGI;
use BundleXml;


print "Content-type: text/html; charset=utf-8\n\n";
my $que = new CGI;
my $code = $que->param('code');
Cyrcitec::parseTemplate('main.html', { root => BundleXml->new->GetHashExt($code) } );

