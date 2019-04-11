#!/usr/bin/perl

no warnings;

use Encode;
# use encoding "koi8-r" , STDOUT => "utf8";
# use encoding "utf8" , STDOUT => "utf8";


# die unless `pwd` =~ m,/socionet/harvest/$dir, ;
$NS = "ranepa";
$arc = "sfukras";

$/ = "</record>";
@rec = <>;
$/ = "\n";
mkdir "dst.tmp";
for $_ ( @rec ) {
	next unless m,<dc:identifier>.*?(\d[\d-]*)</dc:identifier>,s;
	$doc = $1;
# print "$doc\n"; # next;
	next unless m,<dc:type>(.*?)</dc:type>,s;
# print "$1\n";
	next unless $1 =~ m,book|thesis|article,is;
	$type = lc $&;
# print "$type\n";
	undef $series;
	undef $yvi;
	undef $year;
	undef $vol;
	undef $issue;
	undef $pp;
	undef $handle;
	if( $type eq "article" ) {
		if( s,<dc:relation>\s*(20.*?)</dc:relation>,, ) {
			$yvi = $1;      # year volume issue
		}
		if( m,<dc:relation>\s*(.*?)</dc:relation>, ) {
			$journal = $1;
			$yvi = $1 if $journal =~ s,;\s*(20.*),,;
			$series = lc $& if $journal =~ m,humani|techno|biolog|mathem|chemis,i;
			$journal = " <Journal>$journal</Journal>\n";
		}
# print "$yvi\n"; next;
		if( $yvi =~ /(\d{4})\s*(\d+)?\s*\(\s*(\d+)\s*\)/ ) {
			$handle = "y:$1:v:$2:i:$3";
			$year = " <Year>$1</Year>\n";
			$vol = " <Volume>$2</Volume>\n" if $2;
			$issue = " <Issue>$3</Issue>\n";

			if( m,<dc:x-pages>(.*?)</dc:x-pages>, && $1 =~ m,(\d+)\W+(\d+), ) {
				$handle .= ":p:$1-$2";
				$pp = " <Pages>$1-$2</Pages>\n";
			} else {
				undef $handle;
			}
		} else {
			undef $handle;
		}
	} else {
		$series = $type;
	}
	next unless $series;
	$handle = $doc unless $handle;
	$handle = "$NS:$arc:$series:$handle";

# print "$series $year $vol $issue $pp\n"; next;
	mkdir "dst.tmp/$series" unless $dirdone{$series} ++;

	$title = m,<dc:title>(.*?)</dc:title>,s ? $1 : "No title";
	if( m,<dcterms:alternative>(.*?)</dcterms:alternative>,s ) {
		$title .= " // $1";
	}
	$title = " <Title>$title</Title>\n" ; #if $title;

	undef $author;
	$author = join "", map {
		" <Author>\n  <Name>$_</Name>\n </Author>\n";
		} sort
		m,<dc:creator.*?>(.*?)</dc:creator>,gs ;

	$kw = join( ";",
		    map{ s/\s+$//ms; if( /\S/ ){ $_ } else {} } sort
	  m,<dc:subject>(.*?)</dc:subject>,gs
	);
	$kw = " <Keywords>$kw</Keywords>\n" if $kw;

	undef $abstract;
	if( int( @_ = map{ s/\s+$//ms; if( /\S/ ){ $_ } else {} } sort
	  m,<dcterms:abstract>(.*?)</dcterms:abstract>,gs )
	) {
		$abstract = join "", " <Abstract>",
				     (map { "&lt;p&gt;$_\n&lt;/p&gt;\n" } @_),
				     " </Abstract>\n";
	}

	undef $cdate;
	if( m,(?:<dcterms:created>|<dcterms:dateAccepted>)(\d{4}-\d{2}-\d{2}),s ) {
		$cdate = " <Date>\n  <Creation>$1</Creation>\n </Date>\n";
	}

	undef $url;
	undef $fmt;
	if( m,<dc:fulltext.*?/>, ) {
		$f = $&;
		if( $f =~ m,href="(.*?)", ) {
			$url = " <File>\n  <URL>$1</URL>\n";
			$url .=         "  <Format>$1</Format>\n" if $f =~ m,type="(.*?)",;
			$url .= " </File>\n";
		}
	}


	open T, ">dst.tmp/$series/$doc.xml";
print T <<EE;
<?xml version="1.0" encoding="utf-8"?>
<root>
 <Template-Type>$type</Template-Type>
 <Handle>$handle</Handle>
 <DocID>$doc</DocID>
$title$author$abstract$kw$cdate$journal$vol$year$issue$pp$url
</root>

EE
}

