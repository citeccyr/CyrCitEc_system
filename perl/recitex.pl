#!/usr/bin/perl

use Getopt::Std;
getopts('Jjnb:s:');

##(?? no.) if we have no option to sea
my $SPHINX_SEARCH;
my $db_file = $opt_b // '/var/hhome/_sphinx/handle.db';

if( -r $db_file ) {
	use DB_File;
	tie %handle, 'DB_File', $db_file, O_RDONLY
		or die "cannot tie 'handle': $!";
	use DBI;
	$SPHINX_SEARCH = $opt_s // 'host=127.0.0.1;port=9306';
}

$jfile = shift;
die <<EE unless $jfile;
recitex.pl - references and citation extraction
usage: recitex.pl [-Jjn] [-b spx_db_file] [-s spx_ip:port] path/file[.json] [source_handle]
	-j -- dump source text extracted from json
	-J -- dump source text extracted from json, rearranged properly
	-n -- do not find citations, make reference list only
	-s -- Sphinx address:port,
	-b -- db file to convert Sph answer to handle, assoc. with the reference
EE

my $US = "\037";   # ASCII unit separator
use Encode qw( decode encode );


# "pages" template of the reference (... pp. 1-999), bilingual:
$dash = decode("utf8", pack( "CCC", 0xE2, 0x80, 0x93 ), Encode::FB_CROAK ); # 342 200 223
$dash2 = decode("utf8", pack( "CCC", 0xE2, 0x80, 0x94 ), Encode::FB_CROAK ); # 342 200 224
$dashs = $dash.$dash2."-";
$cyr_s = decode( "utf8", $cyr_s = "с", Encode::FB_CROAK );
$cyr_r = decode( "utf8", $cyr_r = "рр?", Encode::FB_CROAK );
$pp = "\\b(pp?|$cyr_r|$cyr_s|c)\\.?\\s*[\\d$dashs]+";

# "et al" template:
$etal = "(:?\\bet\\s+al\\b\\.?|\\bи\\s+др\\b\\.?)";
$etal = decode("utf8", $etal, Encode::FB_CROAK );

$nbsp = pack( "C", 0xa0 );
$nbsp = decode("cp1251", $nbsp, Encode::FB_CROAK );

$jfile .= ".json" if $jfile !~ /\.j\w*$/i;
j2str( $jfile );        # --> @lines: [@transform,offset,str,pageNo] -- [0-8].

($file = $jfile)=~ s,.*/,,;
($dir = $&) =~ s,^(.*/)?j-,,;
$dir =~ s,/$,,;
$file =~ s/\.j\w*$//i;

undef @from_meta;       # - refs from socionet metadata, if any
$source_handle = shift;

if( open( M, "< :encoding(utf8)", "/work/ftp/socionet/$dir/$file.xml") ) {
	undef $/;
	$_ = <M>;
	close M;
	$/ = "\n";

	s,.*<root>,,s; s,</root>.*,,s;
	if( s,<refs>(.*?)</refs>,,s ) {
		@from_meta = map{
			s/\s+$//s;
			if( s/\s+<reference num="\d+".*?>\s+//s ) { $_ } else {}
		} split /<\/reference>/s, $1;
	}
	$fc = defined $source_handle ? 1 : 0;
	while( s,<([-\w]+).*?>(.*?)<,<,s ) {
		$tag = $1;
		$val = $2;
		if( $tag eq "Handle" && ! defined $source_handle ) {
			($source_handle = $val) =~ s/^\s+//s;
			$source_handle =~ s/\s+$//s;
			last if ++ $fc == 2;
		}
		elsif( $tag eq "File" ) {
			if( m,<URL>(.*?)</URL>, ) {
				($file_url = $1) =~ s/^\s+//s;
				$file_url =~ s/\s+$//s;
				last if ++ $fc == 2;
			}
		}
		s,.*?</$tag.*?>,,s;
	}
# print "$source_handle; $file_url\n"; exit;
} else {
  ($parinov_puzyrev_prefix = $dir) =~ s,/,,g;
  if( open( M, "< :encoding(utf8)", "/work/RuPEc/xml/$dir/$parinov_puzyrev_prefix$file.xml" ) ) {
	undef $/;
	$_ = <M>;
	close M;
	$/ = "\n";

	if( !defined $source_handle && m,<attr\s+id="handle">(.+?)</attr>, ) {
		$source_handle = $1;
	}
	if( m,<attr\s+id="file-url">(.+?)</attr>, ) {
		$file_url = $1;
	}
} }

chomp($date = `date -u +%Y-%m-%dT%H:%M:%S.000000+00:00`);

print <<EE;
<?xml version='1.0' encoding='utf-8'?>
<document  id="$file"
 type="citmap"
 updated="$date"
 created="$date"
 provider="RANEPA, CitEcCyr project" 
>

  <source handle="$source_handle"
	  file="$file_url">
    <text rich="http://no-xml.socionet.ru/~cyrcitec/j-$dir/$file.json">
     <input data="http://no-xml.socionet.ru/~cyrcitec/j-$dir/$file.pdf">
EE

# V4: embed jfmt.pl

$pos = $line = $ppnum = 0;

while( ($offset, $str, $x, $x, $axes, $x, $horz, $vert, $pnum ) = @{shift @lines} ) {
# print8( "___Line $line, N:" .int(@{shift @lines})." Page $pnum: $str\n" );
	next if $axes < 0       # ignore vertical string (ask S.Parinov)
	|| $is_colont_vc{ $vert } >= $colont_crit; # ignore (very probably) a colontitle

	if( $ppnum == $pnum &&
	    abs($vpix[$line] - $vert) < 5.5 ) { # same line
		$txt[$line] .= $str;
		$src .= $str;
	} else {                                # new line
		$ppnum = $pnum;
		++ $line;
		$hpix[$line] = $horz;
		$vpix[$line] = $vert;
		$page[$line] = $pnum;
		$lpos[$line] = $pos;
		$pos2line[$pos] = $line;

		$txt[$line-1] .= "\n";
		$src .= "\n";
		$posmap[$pos++] = $offset;

		push @txt, $str;
		$src .= $str;
# print encode('UTF-8', "===$pos->$offset:$str|\n", Encode::FB_CROAK);
	}

	for (0 .. length( $str ) - 1) {
		$pos2line[$pos] = $line;
		$posmap[$pos++] = $offset++;
	}
}

if( ! @txt ) {
	print <<EE;
No text extracted from json file
     </input>
    </text>
  </source>
</document>
EE
	exit 9;
}

$pos2line[$pos] = $line;
$posmap[$pos] = $offset;

if( $opt_j ) {
  print8( $src );
  exit;
}


# "�����������" ������.
undef $src;

 $txt[$#txt] .= "\n";
 push @txt, ""; push @page, 99999; # very large N - experimental.
$pno = 1;
$bstart = 1;    # blk's start line
$vmax = $vmin = $vpix[1];
for $lno (2..$#txt) {
# $src .= "---L:$lno,P:$pno,?:$page[$lno]:$txt[$lno]";

=v1:
	if( $pno == $page[$lno] && $vmin >= $vpix[$lno] ) {     # same page, same blk
		$vmin = $vpix[$lno];
		next;
	}
# v2:
	if( $pno == $page[$lno]                 # same page
	 && $vmin >= $vpix[$lno]                # same or next line
	 && ( int(@blk) == 0                    # no blocks yet at the page
	    || $phmax <= $hpix[$lno] ) ) {
		$vmin = $vpix[$lno];
		$hmax = $hpix[$lno] if $hmax < $hpix[$lno];
		next;
	}
=cut
# v3:
	if( $pno == $page[$lno]                 # same page
	 && $vmin >= $vpix[$lno]                # same or next line
 && $vmin <= $vpix[$lno] + 60
 && $hpix[$lno] * 3 >= $hmax
	 && ( int(@blk) == 0                    # no blocks yet at the page
#            || $hpix[$lno] * 3 >= $hmax         # || �� �����
	    || $phmax <= $hpix[$lno] )          #             � ������ �������
	) {
		$vmin = $vpix[$lno];
		$hmax = $hpix[$lno] if $hmax < $hpix[$lno];
		next;
	}

# new page or new blk
	if( int(@blk) >= 1 ) {
		($pbstart,$pvmax,$pvmin,$pbend) = @{ pop @blk };

		if( $pvmax >= $vmin
		 && $pvmin <= $vmax ) {
# current and last blks intersect:
# $src .= "===Merge current at p=$pno with blk=". int(@blk) ." := $bstart,$vmax,$vmin;\n";
			$vmax = $pvmax if $vmax < $pvmax;
			$vmin = $pvmin if $vmin > $pvmin;
			$bstart = $pbstart;
# -- merged.
		} else {        # just put last block back
			push @blk, [$pbstart,$pvmax,$pvmin,$pbend];
		}
	}

# $src .= "===Push new at p=$pno blk=". int(@blk) ." := $bstart,$vmax,$vmin; line=".($lno-1)."\n";
	push @blk, [$bstart,$vmax,$vmin,$lno-1]; # new 'last' blk
	$vmax = $vmin = $vpix[$lno];    # new 'current' blk
	$bstart = $lno;                 # --------
      $phmax = $hmax;
      $hmax = $hpix[$lno];

	if( $pno < $page[$lno] ) {      # new page
# $src .= "===Page:$pno,Nblk:".int(@blk).",L:$blk[0][0]--$blk[0][3]\n";
# rearrange blks of previous page
# $src .= "===$lno:NEWPAGE $page[$lno]\n";
		# $p = ��������� ������� ��������
		for $i (sort { int(($blk[$b][1] - $blk[$a][1])/3) } (0..$#blk)) {
			for $line ( $blk[$i][0] .. $blk[$i][3] ) {
				$src .= $txt[$line];
			}
			#$pb = $lpos[ $blk[$i][0] ]; # ��������� ������� �����
			#$pe = $lpos[ $blk[$i][3] ] + length $txt[ $blk[$i][3] ]; # ���������
			#while( ($posmap2[$p++] = $pb++) < $pe ) {}
		}
#
# $src .= "===DONE\n";
		$pno = $page[$lno];
		undef @blk;
	}
}
# print8( "X=== p$pno:blk". int(@blk) .":= $bstart,$vmax,$vmin;\n" );

if( $opt_J ) {
 print8( $src );
 exit;
}


# map {print8( $page[$_].":".$vpix[$_].":".$txt[$_] );} (0..$#txt); # exit;

#$src =~ s/$nbsp/ /gs;  # no difference?

# markers of the "References" section:
# v1:
$ref_keyl1 = "references";
push @ref_marker,
 "литература\\s*/\\s*references",
 "библиографический\\s*список",
 "библиографические\\s*ссылки",
 "список\\s*(:?использ(:?ованн|уем)ых)?\\s*источников",
 "список(:?\\s*использованной)?\\s*литературы",
 "использованная\\s*л\\s*и\\s*т\\s*е\\s*р\\s*а\\s*т\\s*у\\s*р\\s*а",
 "библиография:?\\s*\$",
  "русскоязычные\\s*источники\\s*\$",
 "л\\s*и\\s*т\\s*е\\s*р\\s*а\\s*т\\s*у\\s*р\\s*а\\s*\$",
 "источники\\s*\$",
 $ref_keyl1;
for $rk ( @ref_marker ) {
	$rk = decode("utf8", $rk, Encode::FB_CROAK );
	if( $src =~ /(.*)^([^[:alpha:]]*$rk [^\n]*)[\s\[]*1\b/imsux ) {
		$src = $1;
		$rmk = $2;
		$pos = length( $src ) + length( $rmk );
# print8( "$rk\n" );
		$match_type = 1;
		$enum = 1;
		($references = $') =~ s/^\s*\]//s;
		$references = "1$'";
		$dot = $references =~ /^1\./ ? "\\." : "";
		last;
	}
}
# print8( "match_type:$match_type;\n" ); exit;

if( ! $match_type ) {
  for $rk ( @ref_marker ) {
	# $rk = decode("utf8", $rk, Encode::FB_CROAK );
# *****!!! 'decode' leaves the result in it's 2nd argument?!!!
	if( $src =~ /(.*)^([^[:alpha:]]*$rk\W*)/imsux ) {
		$src = $1;
		$rmk = $2;
		$pos = length( $src ) + length( $rmk );
		$match_type = 2;
		$enum = 0;
		$references = $';
		last;
	}
  }
}

#  print8( "=== MATCH:$match_type,POS:$pos->$posmap[$pos],PLINE:$pos2line[$pos],"
#        . substr($src, -120) . "\n========= $rmk\n========= "
#        . substr($references,0,120)."\n\n\n" );
#  exit;

if( $match_type )
{
	$references =~ s/^\s*$ref_keyl1\b.*//imsux;

# print8( "=== enum:$enum, dot:$dot, references:".substr($references, 0,99).">>>\n" );

} else {
	print <<EE;
No references found (1)
     </input>
    </text>
   </source>
</document>
EE
	exit 1;
}
# print "===E:$enum,D:$dot,P:$posmap[$pos];R:", length($references),":", substr($references,0,99),"\n";
 $references =~ s/^\W+//sxu && die "==$&==";    # must not happen
# exit;

# stop words:
$notname = "корректор|редактор|художник|макет|верстка";
$notname = decode("utf8", $notname, Encode::FB_CROAK );

goto UNNUM_REF if ! $enum;

$refno = 1;
if( $references !~ s/^[\s\[]*$refno[\s\]]*$dot\s*(([Vv][oa]n\s*|der?\s*)*([[:upper:]]))/$1/sx ) {
	print <<EE;
No references found (2)
     </input>
    </text>
   </source>
</document>
EE
	exit 2;
}
$pos1 = $pos + length( $& ) - 1; # -> to the beginning of the ref 1
#$pos1 = $pos + length( $& )    ; # -> to the beginning of the ref 1
# print "===POS1:$pos1->$posmap[$pos1]:", substr($references, 0, 500), "\n"; #exit;
$pos = $pos1;
print "      <linking enum=\"1\">\n";
$refno = 2;
$re1 = $references =~ /(.*?)^[\s\[]*$refno[\s\]]*$dot\W*(([Vv][oa]n\s*|der?\s*)*([[:upper:]]))/msx ? 1 : 0;
# -- reference starts from the beginning of the line
# print "===re1:$re1\n"; exit;
$dopreref = 1;
while(
	$re1 &&
	$references =~ s/(.*?)^[\s\[]*$refno[\s\]]*$dot\W*//msx
     || ! $re1 &&
	$references =~ s/(.*?) [\s\[]+$refno[\s\]]*$dot\W*//msx
) {
	$title = $1;
	$pos1 = $pos + length( $& );
	last if $done = $dopreref? prref( $refno-1, $title, $pos ) : 0;
# print8( "===R ".substr($references, 0, 500)."\n===\n" );
	if( $references =~ s/^([Vv][oa]n\s*|der?\s*)*([[:upper:]])/$2/sx
     ||         # false $refno match, search further
	$references =~ s/^[\s\[]*$refno[\s\]]*$dot\W*(([Vv][oa]n\s*|der?\s*)*([[:upper:]]))/$2/msx
     ||
	$references =~ s/ [\s\[]+$refno[\s\]]*$dot\W*(([Vv][oa]n\s*|der?\s*)*([[:upper:]]))/$2/msx
#>>>
	) {
		$pos1 += length( $& ) - 1; # -> to the beginning of the next ref
#print8( "===PRREF <$1:$2>" . ($refno-1) . " $title $pos\n" );
		$dopreref = 1;
	} else {
		$dopreref = 0;
	}
	$pos = $pos1;
	++ $refno;
}
# print "===endloop,R:",substr($references, 0, 500), "\n"; exit;
# printf "=== len: %d; pos: $pos; line: $pos2line[$pos]; page: $page[$pos2line[$pos]]\n", length($references);
# Parinov's rule for the last ref: no more than 4 lines:
for( $i = 0; $i < length($references); ++ $i ) {
	last if $pos2line[$pos]+4 < $pos2line[$pos+$i];
}
# printf "=== 4th line pos: $i; line: $pos2line[$pos+$i]; page: $page[$pos2line[$pos+$i]]\n";
prref( $refno-1, substr( $references, 0, $i ), $pos )   unless $done;
goto SNOSKI;



UNNUM_REF:;    ####### Unnumbered references
print "      <linking enum=\"0\">\n";

$pos += length( $` ) if $references =~ m/((([[:alpha:]$dashs]){2,}\s)(\s*[[:alpha:]]{1,2}\.){1,3}[,\s]*)+/sxu;
$refno = 0;
while(
	$references =~ m/^(([[:upper:]]([[:alpha:]'$dashs])+,?\s)(\s*[[:alpha:]]{1,2}\.){1,3}[,\s]*)+/msxu
#        ||
#        $references =~ m/(([[:alpha:]$dashs]{2,}[,\s])(\s*[[:alpha:]]{1,2}  ) [.,\s]*)+\.\s*/sxu

) {
# print "=== REF:",substr($references, 0, 216), "\n";
	$references = $';
	$athr = $&;
	$ttle = $`;
# print "===T:$ttle\n===A:$athr\n===R:",substr($references, 0, 216), ">>>\n";
	if( $a0 ) {
		$a0 .= $ttle;
		$pos += length( $a0 );
# print "===AT:",++$acnt,":$a0;\n";

###
# In unnumbered list Parinov's rule is applied to every ref!
		for( $i = 0; $i < length($a0); ++ $i ) {
			last if $pos2line[$pos0]+4 < $pos2line[$pos0+$i];
		}
# printf "=== 4th line pos: $i; line: $pos2line[$pos+$i]; page: $page[$pos2line[$pos+$i]]\n";
###
		last if $done = prref( ++ $refno, substr( $a0, 0, $i ), $pos0 );
	}
	$a0 = $athr;
	$pos0 = $pos;
}

if( ! $a0 ) # @title
{
	print <<EE;
No references found (3)
      </linking>
     </input>
    </text>
   </source>
</document>
EE
	exit 3;
} #else
$a0 .= $references;
# Parinov's rule of 4 lines:
for( $i = 0; $i < length($a0); ++ $i ) {
	last if $pos2line[$pos0]+4 < $pos2line[$pos0+$i];
}

prref( ++ $refno, substr( $a0, 0, $i ), $pos0 ) unless $done;

SNOSKI:;
print <<EE;

      </linking>

EE

if( $opt_n || ! @snoska ) {
	print <<EE;
      </input>
    </text>
  </source>
</document>
EE
	exit 0;
}


# search citations in the text.
# 1) like "[rnums]"; rnums ::= rnum | rnum-rnum | rnum,rnums; rnum ::= N[text]M

$ssrc = $src;
goto UNNUM_CIT
		 unless $enum
;

$pos = 0;
$srcl = "";
while( $src =~ /\[([^\]]{1,100})\]/s ) {
	$pref = $`;
	$exact = $&;
	$ref = $1;
	$src = $';
	$pos += length $pref;
	$srcl .= $pref;

	$suff = substr $src, 0, 200;
	if( $src =~ /^(.{200,}?[.?!])\W*[[:upper:]]/s ) {
		$suff = $1;
	}                  # *
	while( $srcl =~ /[.?!]\s+(\W*[[:upper:]])/s && length( $' ) >= 200 ) {
		$srcl = $1.$';
	}
	($pref = $srcl) =~ s/^\s+//s;
	$srcl .= $exact;

	$start = $posmap[$pos];

	$pos1 = $pos + length $exact;
	$end = $posmap[$pos1-1];
	if( $page[$pos2line[$pos]] != $page[$pos2line[$pos1-1]] ) {
		$exact =~ s/\s*\n.*//s;
		$end = $posmap[ $pos + length( $exact ) - 1 ];
	}
	$pos = $pos1;

	$pref = eent( $pref );
	   $pref =~ s/-\n//gms;
	$exact = eent( $exact );
	$suff = eent( $suff );
	   $suff =~ s/-\n//gms;

	$ref =~ s/$pp//gisx;
# print "1===$ref\n";
#        next if $exact =~ /[[:alpha:]]/;
	$ref =~ s/[[:alpha:]]//gs;
	@rlist = map{
		if( /\s/ ) {}
		elsif( /[$dashs]/ ) {
			int($`) < int($')?
			(int($`)..int($')) : {};
		} else {
			int($_);
		}
	} split /\s*[;,]\s*/, $ref;
# print "===",join("//",@rlist),"|\n";
	next if ! @rlist;
	next if grep { $_ < 1 || $_ >= $refno } @rlist;
	if( ! $itr++ ) {
		print <<EE;
      <intextrefs enum="1">
EE
	}
	print encode('UTF-8', <<EE, Encode::FB_CROAK);
	<intextref>
	  <Prefix>$pref</Prefix>
	  <Suffix>$suff</Suffix>
	  <Start>$start</Start>
	  <End>$end</End>
	  <Exact>$exact</Exact>
EE
	for( @rlist )
	{
# print "=== EXACT:$exact;\n";
#?                s/\D.*//g if /^\d/;
		print encode('UTF-8', <<EE, Encode::FB_CROAK); #? if $snoska{$_} || $_ !~ /\D/ && $snoska[$_];
	  <Reference>$_</Reference>
EE
	}
	print <<EE;
	</intextref>

EE
# print "===src:", substr($src, 0, 200),"\n";
}

if( $itr ) {
	print <<EE;
      </intextrefs>
     </input>
    </text>
  </source>
</document>
EE
	exit 0;
}



UNNUM_CIT:;
# 2) search citations like (Author[,year]) | ...
# if enum == 0 or (1) did not succeed.
$pos = 0;
$src = $ssrc; undef $ssrc;
print <<EE;
      <intextrefs enum="0">
EE

$n_match = join( "|", @n_match );
# @n_match - list of templates built from the reference list.

# print encode( "utf8", "$n_match\n", Encode::FB_CROAK ); exit;
$srcl = "";
while( $src =~ /[\[\(]?($n_match)[\.\s]*(:?$pp)?[\]\)]?/isx ) {
	$pref = $`;
	$exact = $&;
	$ref = $1;
	$src = $';
	$pos += length $pref;
	$srcl .= $pref;

# which template matched?
	for( $nr = 0; $nr < @n_match; ++ $nr ) {
		last if $exact =~ /$n_match[$nr]/;
	}
# print encode( "utf8", "===M:$nr+1==$n_match{ $n_match[$nr] }:$n_match[$nr]//\n===E:$exact//\n===R:$ref//\n", Encode::FB_CROAK );
	++ $nr;

	$suff = substr $src, 0, 200;
	if( $src =~ /^(.{200,}?[.?!])\W*[[:upper:]]/s ) {
		$suff = $1;
	}                  # *
	while( $srcl =~ /[.?!]\s+(\W*[[:upper:]])/s && length( $' ) >= 200 ) {
		$srcl = $1.$';
	}
	($pref = $srcl) =~ s/^\s+//s;
	$srcl .= $exact;

	$start = $posmap[$pos];

	$pos1 = $pos + length $exact;
	$end = $posmap[$pos1-1];
	if( $page[$pos2line[$pos]] != $page[$pos2line[$pos1-1]] ) {
		$exact =~ s/\s*\n.*//s;
		$end = $posmap[ $pos + length( $exact ) - 1 ];
	}
	$pos = $pos1;

	$pref = eent( $pref );
	   $pref =~ s/-\n//gms;
	$exact = eent( $exact );
	$suff = eent( $suff );
	   $suff =~ s/-\n//gms;

# print "=== EXACT:$exact;\n";
	print encode('UTF-8', <<EE, Encode::FB_CROAK) ; #if $snoska{$_};
	<intextref>
	  <Prefix>$pref</Prefix>
	  <Suffix>$suff</Suffix>
	  <Start>$start</Start>
	  <End>$end</End>
	  <Exact>$exact</Exact>
	  <Reference>$nr</Reference>
	</intextref>

EE
# print "===src:", substr($src, 0, 200),"\n";
}

print <<EE;
      </intextrefs>
     </input>
    </text>
  </source>
</document>
EE

sub eent {
	my $t = shift;
	$t =~ s/&amp;/&/g;
	$t =~ s/&/&amp;/g;
	$t =~ s/</&lt;/g;
	$t =~ s/>/&gt;/g;
	return $t;
}

sub prref {
	my( $num, $title, $start, $end, $author, $year ) = @_;
# print "===prref $num, $title;\n";
# print "===A:$title;\n";
	chomp $title;
	@year = ($title =~ /\b\d{4}\b/gs);
	$year = join " | ", map{ if( length == 4 && /^1[89]|^20/
				&& ! $year{$_}++ ) { $_ } else {} } @year;
	undef %year;

	$title =~ s/&amp;/&/g;
	$title =~ s/&/&amp;/g;
	$title =~ s/</&lt;/g;
	$title =~ s/>/&gt;/g;
	$title =~ s/\f.*//s;
	$title =~ s/ *-\n//gs;
	$title =~ s/\n/ /gs;
# print "===A:$title;\n";
	my $i, $from_pdf = $title;

	$end = $start - 1 + length $title;
    #? $title =~ s/\b(van|von|der?|...)\b//gis   ?
# print "===$num:E-S:",$end-$start," TL:", length($title),"\n"; return;
	# 8. Preston A,Johnston D. The Future of
	# if( $title =~ /^((([[:alpha:]$dashs]){2,},?\s)(\s*[^\d\W]{1,2}\.){1,3}[,\s]*)+/sxu

	if( $title =~ /^( (?:[Vv][oa]n\s*|der?\s*)*
			  (?: [[:upper:]] (?:[[:alpha:]'$dashs])+,?\s )
			  (?:\s*[[:alpha:]]{1,2}\.){1,3}(and|,|\s)* )+/sxu
#                        van der Lugt N.M., van Kampen A., Walther  F.J.,...
	# 2. Kramer B, Bosman J. Survey of
	# 12. Kogalovsky, M., Parinov, S. The taxonomy of
	 || $title =~ /^(([[:alpha:]]{2,}[,\s])(\s*\w{1,2}  ) [.,\s]*)+\.\s*/sxu
	) {
		$title = $';
		$author = $&;

		$author =~ s/\b\w{1,2}\b//gu;
		$author =~ s/[^[:alpha:]'$dashs]/ /gu;
# print encode( "utf8", "===T,A:$title===$author===\n" );
	}
	undef $url;

	if( $title =~ m=(\burl\W*)?(https?://[-.\w]+(/\S*)?)=iu ) {
		($url = $2) =~ s/[.,]+$//u;     # 20170509 S.Parinov
		$url=~s|"|&quot;|g;             # T.Krichel
		$url = "\n    url=\"$url\"";
# printf "===URL: $url\n===TITLE: $title\n";
	}

	if( ! $author &&
	    $title =~ /(.*?\W[[:alpha:]]{1,2}\.\s*)([^.]{30})/su ) { # 30 non-dots -- S.Parinov
		$title = $2 . $';
		($author = $1) =~ s/\n/ /gsu;
		$author =~ s/\b\w{1,2}\b//gu;
		$author =~ s/[^[:alpha:]'$dashs]/ /gu;
# print "===T2:$title\n===A2:$author\n";
	}
	return 1 if $author =~ /^\s*($notname)\b/i;     # 20170907
	$title =~ s/$etal//i;
# - is not recognized as author name => left in the beginnig of the title
						# remove:
	while( $title =~ s/\([^()]*\)//gsu ) {} # - (...)
	$title =~ s,^\W+,,su;                   # - non-alphanum in the beginning
	$title =~ s,//.*,,su    or              # - from //
	    $title =~ s,/.*,,su;                # - from / if there were no //
	$title =~ s/^(.{16,}?)\..*/$1/u;        # - from '.' after 16-th position
	$title =~ s,\s[[:alpha:]]\..*,,su;      # - from a single letter+'.'
	$title =~ s,\s((url\W*)?https?          # - from [url ]http:
			|url                    #      url:
			|editors                #      editors:
			|спб\.?     #      sPB:
			):.*,,isux;

	$title =~ s/[^-\w]/ /gs;        # \W
	$title =~ s/\s+$//gs;

	undef $handle;
	undef $handle_sup;
      if( $SPHINX_SEARCH ) {
# Try to find the repec/socionet handle of the referenced pub:
	$t = ($title =~ /\w/su)? "\@title $title " : "";
	$a = ($author =~ /\w/u)? "\@author $author " : "";  # quotes?
	$y = $year? "\@year $year " : "";

	if( $aty = "$a$t$y" ) {
	   open OLDERR, ">&", \*STDERR;
	   open STDERR, ">/dev/null";
	    #? TK@20180228 $aty =~ s/\s-+|-+\s/ /gs;
		my $dbh = DBI->connect("dbi:mysql:$SPHINX_SEARCH",
			"_sphinx", "", {'mysql_enable_utf8' => 1} )
		 or die "Failed to connect via DBI";

		$aty =~ s/'/\\'/g;
# print8( "=== $aty\n" );

		my $sth = $dbh->prepare_cached("SELECT * FROM repsoc WHERE MATCH( '$aty' )");
		$sth->execute();
		undef @handle;
		while (my $row = $sth->fetchrow_arrayref) {
		       push @handle, $handle{ $row->[0] };
		}
		#if( @handle == 1 )      # ignore if more then 1 found
		if( @handle )
		{
			chomp $handle[0];
			$handle = "\n    handle=\"$handle[0]\"";
			if( @handle > 1 ) {
				shift @handle;
				$handle_sup = "\n    handle_sup=\""
					. join( " ", @handle ) . "\"";
			}
			$handle =~ s/&/&amp;/g;
			$handle_sup =~ s/&/&amp;/g;
		}
	   open STDERR, ">&OLDERR";
	}
      }

	if( $from_meta = shift @from_meta ) {
		$from_meta = "\n    <from_metadata>$from_meta</from_metadata>";
	}
# create a template to search citation in the text:
	if( $author =~ /[[:alpha:]]/ ) {
		my @author = split /\s+/, $author;
		my $y = $year? ",\\s*$year[0]" : "";
		$n_match = "(:?" . join( ",\\s*", @author ) . $y;
		if( @author > 2 ) {
		      $n_match .= "|$author[0]\\s+$etal$y";
		}
		$n_match .= ")";
	} else {
		$n_match = "(:?^no-match--this-is-a-place-holder\$)";
		$n_match = decode( "utf8", $n_match, Encode::FB_CROAK );
	}
	push @n_match, $n_match;
	$n_match{ $n_match } = $num;
# print "===$num,",int(@n_match),":", $n_match[$#n_match], ";\n";
	print encode('UTF-8', <<EE, Encode::FB_DEFAULT); # FB_CROAK;
<reference
    num="$num"
    start="$posmap[$start]"
    end="$posmap[$end]"$url
    author="$author"
    title="$title"
    year="$year"$handle$handle_sup>
    <from_pdf>$from_pdf</from_pdf>$from_meta
</reference>
EE
	$snoska[$num] = 1;
	return 0;
}

# Read json file, make list @lines of "str" and "transform" data
sub j2str {     # arg == j-file
	my $lxm, $cpage, $prvi7, %if_colontit, $vlen, $waitval;
	my %brace = ( "[" => 1, "]" => 1, "{" => 1, "}" => 1, ":" => 1, );

	open JF, $_[0] or die "$_[0] not found";
	undef $/;
	my $src = <JF>;
	$/ = "\n";
	eval {$src = decode("utf8", $src, Encode::FB_CROAK );};

	my $offset = 0;
	for( split /"page":/, $src ) {  # extra loop just for efficiency
	  next unless /^(\d+),/;
	  $_ = '"page":'.$_;
	  while( /^\s*( [\[{:,}\]]      # main loop
		     | ".*?"
		     |false|true|null
		     |[-\d.e]+ )/sx ) {
		$_ = $';
		$lxm = $&;
		next if $brace{$lxm};
# print "---:$&;\n";
		if( $lxm eq '"page"' && s/:\s*(\d+),// ) {
			$cpage = $1;
# print "===P:$cpage\n";
			next;
		}
		if( $lxm eq '"transform"' ) {
			s/[^\]]*\]//s;
			(my $tf = $&) =~ s/[^-,.\d]//g;
# { print8( "___I:".int(@item).":".join("//",@item)."//TF:$tf\n" ); }
			push @item, map{int($_)} split( /,/, $tf ); # [2-7]
			if( $item[7] != $previ7 ) {
				if( ($str = $item[1]) =~ /^\s*\d+\s*$/ ) { # a single number on a new line
					$str = "pReSuMaBlY,pAgEnUmBeR";
# print "===$& -- $str\n";
				}
				my $t = join( $US, $str, $item[6], $item[7] );
				++ $if_colontit{ $t }   if $item[4] >= 0;
# str+Hcoord+Vcoord - candidate to 'running headline'(?)
				$previ7 = $item[7];
# print "===CT:$if_colontit{ $t}:$t|\n" if $if_colontit{ $t} > 1;
			}
			push( @lines, [@item,$cpage] ) if $item[4] >= 0;
			undef @item;
			next;
		}

		if( $lxm eq "," ) {
			if( $vlen ) {
				$offset+=$vlen;
				$vlen = 0;
			}
			next;
		}

		if( $lxm eq '"str"' ) {
# print ">>>str!\n";
			$waitval = 1;
			next;
		}

		if( $waitval ) {        # value of "str", content.
AGAIN:;
			if( $lxm =~ /\\/ ) {
# print "===$offset:$lxm>>\n";
				$lxm =~ s/\\u00[01][0123456789abcdef]/-/g
						# @#$#$%#$ !!!!
					and goto AGAIN;
# print "===$offset:$lxm>>";
				$lxm =~ s/\\\\/bAcKsLaSh/g;     # backslash itself
				while( $lxm =~ s/\\"$/"/ ) {    # screened '"'
					s/^.*?"//;
					($lxm .= $&) =~ s/\\\\/bAcKsLaSh/g;
				}
# print ">>$lxm";
				$lxm =~ s/\\t/\t/g;
				$lxm =~ s/bAcKsLaSh/\\/g;
# print ">>$lxm\n";
			}
			$lxm =~ s/^"//;
			$lxm =~ s/"$//;
			$vlen = length $lxm;
# print "===WV:$vlen:$lxm;\n";
# 20170922: -- all 3 demo's are ok with this!
			$vlen = 0 if $lxm eq " ";
			push( @item, $offset, $lxm );   # [0,1]
# print8( "===J2S:$offset:$vlen:$lxm;\n" );
			$waitval = 0;
			$lxm = '"'.$lxm.'"';
		}
	  }
	}

# determine V-coord of colontitles ('running headlines'?):
	$colont_crit = 3 if( $colont_crit = int($cpage)/2 ) < 3;
	for ( keys %if_colontit ) {
		if( $if_colontit{$_} > 1 ) {
			$is_colont_vc{ my $t = (split /$US/)[2] } += $if_colontit{$_}; # str+Hcoord+Vcoord
# print "===CTV:$_->$if_colontit{$_}:$t:$is_colont_vc{ $t}\n";
		}
	}
}

sub print8 { print encode('UTF-8', $_[0] ); }


