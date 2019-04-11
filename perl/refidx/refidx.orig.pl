#!/usr/bin/perl

=descr
reference index -- see "new phase" intercourse @ 201808{27-31}.
( Thomas, sorry!!! --Vic :)

Task: given
	<handle + reference number>
output all
	<handle + reference number>
of the _alike_ references.

Introduce
"canonical" representattion (CR) of the alike references:
Doi or (if no Doi) 'Author@Title@Year' where
  A,T have only letters (lowercased) and digits left,
  Y: 4 digits-beginning string, D: verbatim

lrn - local reference number within the reference list of the article
grn - globe (unique) reference number within the index
refid = 'lrn@handle'

data structure:
 Hash %G (file r_id2n.db): refid -> grn
 List of lists @s_list (storable, file r_list.stor): grn -> [ refid ]
      - list of reference identifiers of the same CR (see above)
 Hash %grn (file r_atyd2n.db): ATY or DOI -> grn
      - aux., to update the index
=cut


use Encode qw( decode encode );
use Storable;
use DB_File;
use Getopt::Std;

if( ! @ARGV ) {
	print<<EE;
Usage: refidx.pl options archives
 options:
  -r (source) reference hierarchies directory
  -b target db directory
  -i include only files matching this regex
  -v verbose (debugging)
 archives: if not specified, all content of source directory ('regex' filtered)
EE
	exit 1;
}

my %o;
getopts('b:i:v:r:',\%o);

my $r_dir = $o{'r'} // '/home/cyrcitec';
my $db_dir= $o{'b'} // '/var/hhome/vic/lafka';
my $regex = $o{'i'};
tie %G, 'DB_File', "$db_dir/r_id2n.db" or die "tie $db_dir/r_id2n.db";
tie %grn, 'DB_File', "$db_dir/r_atyd2n.db" or die;
$listfile = "$db_dir/r_list.stor";
chdir $r_dir or die;
push @ARGV, "." if ! @ARGV;

$globcnt = $grn{""};
if( -s $listfile ) {
  $s_list = retrieve $listfile;
  die "inconsistency1" unless $globcnt;
} else {
  die "inconsistency2" if $globcnt;
  push @{ ${$s_list} [0] } , 'lrn@handle'; # initial storing
}

while( $arc = shift ) {
  $arc = "r-$arc" if -d "r-$arc";
  die "I can't deal with your argument $arc" unless -d $arc;

  open F, "find $arc -type f|";

  while( <F> ) {
    chomp;
    next if $regex && ! /$regex/;

    $file=$_;
    print "I look at $file\n"   if $o{'v'};
    open X, $_ or die;
    undef $/;
    @xml = split /<\/reference>/, decode( "utf8", $xml = <X>, Encode::FB_CROAK );
    $/ = "\n";
    pop @xml;
    next if $xml[0] !~ /<source handle="(.*?)"/;
    $handle = $1;
    if(not $handle) {
      print "$file has no handle\n";
      next;
    }
    $lrn = 0;       # local ref number
    for (@xml) {
      ++ $lrn;
      undef $aty;
      if( /doi="(.+?)"/s ) {
	# if doi exists do not use aty
	$doi = encode( 'UTF-8', $1 );
	$grn = $grn{ $doi }
	  or $grn = $grn{ $doi } = ++ $globcnt;
      }
      else {
	next unless /\bauthor="(.*?)"/ms;
	next unless ($a = $1) =~ /[[:alpha:]]/;
	$a =~ s/\s+//g;
	$a =~ s/[^[:word:]]//g;

	next unless /\btitle="(.*?)"/ms;
	next unless ($t = $1) =~ /[[:alpha:]]/;
	$t =~ s/\s//g;
	$t =~ s/[^[:word:]]//g;

	# next unless   # ignore/do not ignore references w/o year
	$y = /year="(\d{4}.*?)"/s ? $1 : undef;
	$y =~ s/\s+//g;
	$y =~ s/[^[:word:]]//g;

	$aty = encode( 'UTF-8', lc join '@', $a, $t, $y );
	$grn = $grn{ $aty }
	  or $grn = $grn{ $aty } = ++ $globcnt;
	undef $doi;
      }
      $offset = /start="(.*?)"/s ? $1 : undef;
      if( $grn0 = $G{ $lrn.'@'.$handle } ) {
	die "remap: $file $grn->$grn0 at ".$lrn.'@'.$handle if $grn0 != $grn;
      } else {
	$G{ $lrn.'@'.$handle } = $grn;
	if( $o{'v'} ) {    # debugging mode
	  push @{${$s_list}[$grn]},
	    join( '@',$lrn,$handle,$offset,$aty.$doi);
	} else {
	  push @{${$s_list}[$grn]} ,
	    join( '@',$lrn,$handle,$offset);
	  # offset - S.Parinov's favorite attribute
	}
      }
    }
  }
}
$grn{""} = $globcnt;
store $s_list, $listfile;

