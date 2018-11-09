#!/usr/bin/perl
no warnings;

# 20180914 ну началось...

use DB_File;
use Storable;
use CGI;
use Encode qw( decode encode );

$fquery = new CGI;
   $rnum = $fquery->param("r")
or $rnum = $fquery->param("num");
   $handle = lc $fquery->param("h")
or $handle = lc $fquery->param("handle");
$vis = $fquery->param("v");
$all = $fquery->param("a");

tie %G, 'DB_File', "/home/cyrcitec/r_id2n.db", O_RDONLY or die;
$List = retrieve "/home/cyrcitec/r_list.stor" or die;

print <<EE;
Content-type: text/xml; charset=utf-8

<?xml version="1.0" encoding="utf-8"?>
EE

if( $all ) {    # упорядочить по уменьшению количества цитирующих публикаций
	for $i (0 .. $#{$List}  ) {
		$n = int( @{ ${$List}[$i] } );
	# print $n,"\n";
		if( $n >= $all ) {
			$rpt{ ${ ${$List}[$i] }[0] } = $n;
		}
	}
	$rnum = int( keys %rpt );
print <<EE;
<refarg num="$rnum" all="$all">
EE
	map{    ($lrn, $h, $off) = split '@', $k = $_;
		if( $vis ) {
			($a,$t,$y) = get_aty($lrn, $h);
			print encode('UTF-8', <<EE, Encode::FB_CROAK);
  <reference ncit="$rpt{$k}" num="$lrn" handle="$h" start="$off"
    author="$a"
    title="$t"
    year="$y"/>
EE
		} else {
			print "  <reference ncit=\"$rpt{$_}\" num=\"$lrn\" handle=\"$h\" start=\"$off\"/>\n"
		}
	} sort{ $rpt{$b} <=> $rpt{$a} } keys %rpt;

	print "</refarg>\n";
	exit 0;
}

$grn = $G{ $rnum . '@' . $handle };
undef $grn if $grn eq '@';

print <<EE;
<refarg num="$rnum" handle="$handle" all="$all">
EE
for $j (0 .. $#{ ${$List}[$grn] } ) {
	# ($lrn, $h, $off, $aty) = @{ ${ ${$List}[$grn] }[$j] };
	($lrn, $h, $off, $aty) = split '@', ${ ${$List}[$grn] }[$j], 4;
	if( $vis ) {
		($a,$t,$y) = get_aty($lrn, $h);
		print encode('UTF-8', <<EE, Encode::FB_CROAK);
  <reference num="$lrn" handle="$h" start="$off"
    author="$a"
    title="$t"
    year="$y"/>
EE
	} else {
		print "  <reference num=\"$lrn\" handle=\"$h\" start=\"$off\"/>\n";
	}
}

print "</refarg>\n";
exit 0;

sub get_aty {
	my( $lrn, $handle, $ns,$arc,$series,$code ) = @_;
	my @r = ( "", "", "" );
	($ns,$arc,$series,$code) = split ":", $handle, 4;
	open X, "/home/cyrcitec/r-$arc/$series/$code.xml" or return @r;
	undef $/;
	($_) = grep { /num=\"$lrn\"/ }
		split /<\/reference>/, decode( "utf8", $xml = <X>, Encode::FB_CROAK );
	$/ = "\n";
# print $ref,"\n";
	$r[0] = $1 if /author="(.*?)"/s;
	$r[1] = $1 if /title="(.*?)"/s;
	$r[2] = $1 if /year="(.*?)"/s;
	return @r;
}
