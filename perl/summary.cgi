#!/usr/bin/perl

# ./summary.cgi -o /home/prl/opt/refidx/summary.json -d /home/prl/www/bundles/en/xml


use strict;
use POSIX;
use Getopt::Std;
use lib './Modules';
#use lib '/home/socionet/public_html/cgi/modules';
use MyXMLParser;
use LWP::Simple;
use Data::Dumper;
use Cyrcitec;

$| = 1; #flush output
my $trace = 1;							# output some trace info during parsing
my $dir = '/home/cec/public_html/opt/bundles/xml';  		# dir for parsing
#my $dir = '/home/cec/public_html/opt/bundles/repec/xml';  		# dir for parsing
my $summary_out = 'summary.xml';				# simple xml file with summary for each id
my $xml_in = '/home/cec/public_html/opt/bundles/index.xml';	# xml file for add summary attribute
my $xml_out = 'index2.xml'; # '/home/cec/public_html/opt/bundles/xml/index.xml'; # where to save changed xml file
my $html_in = '/home/cec/public_html/opt/bundles/index.html';	# html file for adding summary info column
my $html_out = 'index2.html';					# where to save changed html file
my $json_out = 'summary.json';

my %o;
getopts('o:d:',\%o);
## -c directory with configs
## -o out json file
if($o{'d'}) { $dir = $o{'d'}; }
if($o{'o'}) { $json_out = $o{'o'}; }

my $xsum = GetSummaryHash();
#CreateSummary($xsum);	# do work with summary data
CreateJsonSummary($xsum);	# do work with summary data
#CreateXml($xsum);	# do work with xml file
#CreateHtml($xsum);	# do work with html file


# ------------------------------------------------------------------------------------------------------

sub CreateHtml
{
    if($html_in) {
	my $html = Cyrcitec::GetFileContent($html_in);
	$html =~ s/ align="left" style="align: left"//g;
	$html =~ s/ href="(xml|pub|cit)/ href="..\/$1/g;
	$html =~ s/<tr([^`]+?)<\/tr>/"<tr".addTD($1,$_[0])."<\/tr>"/eg; #"
	if($html_out) { Cyrcitec::SaveFileContent($html_out, $html); }
	else { print $html; }
    }
}
sub addTD
{
    my $html = $_[0];
    my $h = $_[1];
    if($html =~ /xml\/([^\.]+)\.xml/) {
	$html .= "<td><a href=\"spadist4bundle.cgi?code=$1\">".$h->{$1}."</a></td>";
    }
    return $html;
}

sub CreateXml
{
    my $h = $_[0];
    if($xml_in && $xml_out) {
	my $xml = Cyrcitec::GetFileContent($xml_in);
	$xml =~ s/bunshid="([^"]+)"([^\/]+)/"bunshid=\"".$1."\"".$2." summary=\"".$h->{$1}."\""/ge; #"
        Cyrcitec::SaveFileContent($xml_out, $xml);
    }
}


sub CreateJsonSummary
{
    my $h = $_[0];
#print Dumper($h); exit;
    if($json_out) 
    {
	my $data = '{';
	foreach my $k (keys %$h) {
	    $data .= ',"'.$k.'":"'.$h->{$k}.'"';
	}
	$data .= '}'; $data =~ s/^{,/{/;
	Cyrcitec::SaveFileContent($json_out, $data);
    }
}

sub CreateSummary
{
    my $h = $_[0];
    if($summary_out) 
    {
	my $nl = "\n";
	my $data = '';
	$data = '<bundles count="'.scalar(keys %$h).'">'.$nl;
	foreach my $k (keys %$h) {
	    $data .= ' <bundle bunshid="'.$k.'" summary="'.$h->{$k}.'" />'.$nl;
	}
	$data .= '</bundles>';
	Cyrcitec::SaveFileContent($summary_out, $data);
    }
    
}

sub GetSummaryHash
{
    my $res;
    my $nl = "\n";
    if($trace) { print 'start at '. strftime("%H:%M:%S", localtime(time))."\n"; } #%Y-%m-%d
    my @matches = $dir ? getCodesListOnDir($dir) : getCodesList();
    my $cnt = @matches;
    if($trace) { print 'Count: ' . $cnt.$nl; } 
    for(my $i = 0; $i < @matches; $i++) {
	my $code = $matches[$i];
	my $idx = $i + 1;
        #if($trace) { print $dir.'/'.$code.'.xml'; } 
	my $h = $dir ? Cyrcitec::GetHashByFilePath($dir.'/'.$code.'.xml') : Cyrcitec::GetHashByCode($code);
	$res->{$code} = $h->{$code}->{intextsummary};
	if($trace) { print ' '.($i + 1); }
	#$i = 1000 if $i > 5;
    }
    if($trace) { print $nl.'end at '.strftime("%H:%M:%S\n", localtime(time)).$nl; }
    return $res;
}

#sub prn {
    #if($FH) { print $FH $_[0]; } 
    #else { print $_[0]; }
#}

sub getCodesList
{
    my $url = "http://cirtec.ranepa.ru/analysis/xml/";
    my $content = get $url;
    my @matches = $content =~ /<a href="[^\.]+.xml">([^\.]+).xml<\/a>/g;
    #print "??".$matches[0];
    return @matches;
}

sub getCodesListOnDir
{
    my $dir = $_[0];
    my @matches;
#push @matches, 'slgvni'; return @matches;
    opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
    while (readdir $dh) {
	my $d = $_;
	if($d =~ /([^\.]+)\.xml/) { push @matches, $1; }
    }
    closedir $dh;
    return @matches;
}



sub dbg {
	if( ref($_[0]) eq 'HASH' || ref($_[0]) eq 'ARRAY' ) { print Dumper($_[0]); }
	elsif($_[0]) { print $_[0]."\n"; }
	else { print "-EMPTY-\n"; }
}
sub me {
	dbg(shift);	exit;
}