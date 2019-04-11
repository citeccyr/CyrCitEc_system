#!/usr/bin/perl

# rm /home/prl/opt/refidx/r_*; /home/prl/perl/refidx/refidx.pl -r /home/cec/opt/peren/ -i summary.xml -b /home/prl/opt/refidx
# /home/prl/perl/summary.cgi -o /home/prl/opt/refidx/summary.en.json -d /home/prl/www/bundles/en/xml
# /home/prl/perl/summary.cgi -o /home/prl/opt/refidx/summary.ru.json -d /home/prl/www/bundles/ru/xml
#
#    > $LOG/bundles.log
#    create citcon4bundles:
# cd /home/prl/perl;/home/prl/perl/citcon4bundles.pl -o /home/prl/opt/refidx/citcon4bundles.en.txt -d /home/prl/www/bundles/en/xml
# cd /home/prl/perl;/home/prl/perl/citcon4bundles.pl -o /home/prl/opt/refidx/citcon4bundles.ru.txt -d /home/prl/www/bundles/ru/xml
#    create topic_output.json, words_freqs.json:
# /usr/bin/python3.7 /home/prl/perl/refidx/parse_contexts.py -i /home/prl/opt/refidx/citcon4bundles.en.txt -o /home/prl/opt/refidx/
#   mv /home/prl/opt/refidx/topic_output.json /home/prl/opt/refidx/topic_output.en.json; mv /home/prl/opt/refidx/words_freqs.json /home/prl/opt/refidx/words_freqs.en.json; 
# /usr/bin/python3.7 /home/prl/perl/refidx/parse_contexts.py -i /home/prl/opt/refidx/citcon4bundles.ru.txt -o /home/prl/opt/refidx/
#   mv /home/prl/opt/refidx/topic_output.json /home/prl/opt/refidx/topic_output.ru.json; mv /home/prl/opt/refidx/words_freqs.json /home/prl/opt/refidx/words_freqs.ru.json; 
# /usr/bin/python3.7 /vol/home/prl/temp/create_json_grams.py --in-filename /home/prl/opt/refidx/citcon4bundles.en.txt --out-filename /home/prl/opt/refidx/grams.en.json
# /usr/bin/python3.7 /vol/home/prl/temp/create_json_grams.py --in-filename /home/prl/opt/refidx/citcon4bundles.ru.txt --out-filename /home/prl/opt/refidx/grams.ru.json
# /home/prl/perl/refidx/bundles.cgi -e en
# /home/prl/perl/refidx/bundles.cgi -e ru

# GROUPS:
# mkdir /home/prl/opt/groups/Christopher-Baum; rm /home/prl/opt/groups/Christopher-Baum/r_*; /home/prl/perl/refidx/refidx.pl -r /home/cec/public_html/opt/groups/Christopher-Baum -i packet.xml -b /home/prl/opt/groups/Christopher-Baum
# cd /home/prl/perl; /home/prl/perl/summary.cgi -o /home/prl/opt/groups/Christopher-Baum/summary.json -d /home/prl/www/groups/Christopher-Baum/xml
# cd /home/prl/perl; /home/prl/perl/citcon4bundles.pl -o /home/prl/opt/groups/Christopher-Baum/citcon4bundles.txt -d /home/prl/www/groups/Christopher-Baum/xml
# /usr/bin/python3.7 /home/prl/perl/refidx/parse_contexts.py -i /home/prl/opt/groups/Christopher-Baum/citcon4bundles.txt -o /home/prl/opt/groups/Christopher-Baum/
# /usr/bin/python3.7 /vol/home/prl/temp/create_json_grams.py --in-filename /home/prl/opt/groups/Christopher-Baum/citcon4bundles.txt --out-filename /home/prl/opt/groups/Christopher-Baum/grams.json
# NO NEED -- /home/prl/perl/refidx/xcont_and_crorf.cgi -g Christopher-Baum
# /home/prl/perl/refidx/bundles.cgi -g Christopher-Baum

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
use Data::Dumper;
use Cec::Groups;

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
mkdir($db_dir) if !-d $db_dir;
tie %G, 'DB_File', "$db_dir/r_id2n.db" or die "tie $db_dir/r_id2n.db";
tie %grn, 'DB_File', "$db_dir/r_atyd2n.db" or die;
tie %cits, 'DB_File', "$db_dir/r_cits.db" or die "tie $db_dir/r_cits.db";
$listfile = "$db_dir/r_list.stor";
chdir $r_dir or die;
push @ARGV, "." if ! @ARGV;
my @exceptions = ('repec:bkr','repec:cfr','repec:eus','repec:hig','repec:mmb');
my $exc_count;

$globcnt = $grn{""};
if( -s $listfile ) {
  $s_list = retrieve $listfile;
  die "inconsistency1" unless $globcnt;
} else {
  die "inconsistency2" if $globcnt;
  push @{ ${$s_list} [0] } , 'lrn@handle'; # initial storing
}
my $gnames = $Cec::Groups::names;
#me( $gnames );

while( $arc = shift ) {
  $arc = "r-$arc" if -d "r-$arc";
  die "I can't deal with your argument $arc" unless -d $arc;

  open F, "find $arc -type f|";

  while( <F> ) {
    chomp;
    next if $regex && ! /$regex/;
 #next if $_ eq './cited_papers.packet.xml';
    $file=$_;
    
    my $group = '';
    if ($file =~ /([^\/]+).packet.xml$/) { $group = $1; }

    open X, $_ or die;
    undef $/;
    if($group) { @xml = split /<\/source>/, decode( "utf8", $xml = <X>, Encode::FB_CROAK ); }
    else { @xml = split /<\/reference>/, decode( "utf8", $xml = <X>, Encode::FB_CROAK ); }
    $/ = "\n";
    pop @xml;
    next if $xml[0] !~ /<source handle="(.*?)"/;
    $handle = $1;
    print "I look at $file with handle $handle\n"   if $o{'v'};
    if(not $handle) {
      print "$file has no handle\n";
      next;
    }
    if(my $sr = is_exception($handle)) {
    	print "$file has no handle\n";
    	$exc_count->{$sr} ++;
      next;
    } 
    
    if(!$group) {
    	my @xml0 = split /<reference /, $xml[0]; $xml[0] = @xml0[1]; # prl: fix start value, because this attr may exists in "<version" tag!
  	}
    $lrn = 0;       # local ref number
dbg( $file.'  '.$group.': ' .(scalar @xml) );
    for (@xml) {
    	#me($_);
      ++ $lrn;
#next if $lrn>5;
      undef $aty;
      # group way:
      if( $group ) {
      	my $idx = 0;
      	$grn = 0;
      	if (/<source handle="(.*?)"/) { $handle = $1; };
      	foreach my $grp (@$gnames) {
      		$idx++;
      		if($grp eq $group && !$grn{ $group }) { $grn{ $group } = $idx;  $globcnt++; } #$grn = $idx; }
      	}
      	#next if $grn == 0;
      	$grn = $grn{ $group }
				  or next; #$grn = $grn{ $doi } = ++ $globcnt;
      }
      elsif( /doi="(.+?)"/s ) {
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
      
      #cits number:
      if(/<linking[^>]*>([^\0]+)<\/linking>/) {
      	my $refs = $1; 
    		my @c = $refs =~ /<\/reference>/g;
				$cits{$handle} = scalar @c;
    	}
      #end cits number.
      
      $offset = /start="(.*?)"/s ? $1 : undef;
      
      #dbg($handle.' ' .$offset );
      if(!$group) {
      	if( $grn0 = $G{ $lrn.'@'.$handle } ) {
					die "remap: $file $grn->$grn0 at ".$lrn.'@'.$handle if $grn0 != $grn;
				}
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


#dbg(\%G);
#dbg($s_list);

print 'exception: '.Dumper($exc_count);
$grn{""} = $globcnt;
store $s_list, $listfile;

#dbg($s_list);
#dbg(scalar $s_list->[$grn{'citing_papers'}]);
#dbg(\%grn);
dbg(\%cits);

sub is_exception {
	my $handle = $_[0];
	foreach my $k (@exceptions) {
		if($handle =~ /^$k:/) { return $k; }
	}
	return '';
}

sub id {
	use Digest::MD5 qw(md5 md5_hex md5_base64);
  my $b=shift;# // confess "I need this defined.";
  #my $md5  = Digest->new("MD5");
  my $md5 = Digest::MD5->new;
  $md5->add($b);
  my $out=$md5->b64digest();
  $out=~s|\+||g;
  $out=~s|/+||g;
  $out=substr($out,0,6);
  return $out;
}


sub dbg {
	if( ref($_[0]) eq 'HASH' || ref($_[0]) eq 'ARRAY' ) { print Dumper($_[0]); }
	elsif($_[0]) { print $_[0]."\n"; }
	else { print "-EMPTY-\n"; }
}
sub me {
	dbg(shift);	exit;
}