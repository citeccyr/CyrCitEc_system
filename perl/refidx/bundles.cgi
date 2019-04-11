#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(confess);
#use CGI;
use DB_File;
use File::Basename;
use Data::Dumper;
use Digest;
use Digest::MD5 qw(md5);
#use Encode qw( decode encode );
use Getopt::Std;
use List::Util qw(shuffle);
use Storable;
use XML::LibXML;
use URI::Escape;
use JSON::XS;

use Cidig::Ris;
use Cec::Bundles;
use Cec::Dates;
use Cec::Groups;
use Cec::Store;
use Cec::Paths;
use Cec::Meta;
use Cec::Recitex;
use Cec::Xml;
use Cec::Xslt;
# use Cec::Thomas;

use lib '/home/prl/perl/Modules/';
use BundleConfig;

#use Ernad::Shoti;

binmode(STDOUT,'utf8');

my $files=$Cec::Paths::files;
my $dirs=$Cec::Paths::dirs;

our $xpc = XML::LibXML::XPathContext->new();

my $citer_sheet;

my @web_types=('cit','pub','cro','dis');
my $web_sheet;

my $md5  = Digest->new("MD5");
## all read times set to the start of the script
my $now=&Ernad::Shoti::now();

## index of files
my $bunshids;

## crorf data
my $crorf;

## spadis data
my $spadis;

## bundles index
my $bx;

## -r restrict
my %o;
getopts('m:ibs:r:cowdipRg:e:',\%o);
## -m minimum number
## -b create bundles
## -i index bundles
## -s show bundles
## -w build html
## -r restrict to a bundle
## -c clear files
## -o crorf only
## -d spacial distriution only
## -f build crorf html
## -p production version
## -R repec version
## -g group input
## -e use prl's settings for build_bundles && build_index
##    =en like english series
##    =ru like russian series
#my %settings = get_settings($o{'e'});
my %settings = %{BundleConfig->new($o{'e'} || $o{'g'})};
mkdirs(\%settings) if $settings{'conf'};


## default minimum, 10 for now
if(not $o{'m'}) {
  $o{'m'}=10;
}
## for RePEc version, take 3
if($o{'R'}) {
  $o{'m'}=3;
  ## change to the RePEc dirs, a very awkward hack
  &repec_dirs();
}


if($o{'c'}) {
  &clear();
}

if($o{'b'}) {
  &build_bundles();
  exit;
}

if($o{'d'}) {
  &inject_spadiss();
  exit;
}

if($o{'o'}) {
  &inject_crorfs();
  exit;
}

if($o{'o'}) {
  &build_crorf_html();
  exit;
}

if($o{'i'}) {
  &build_index();
  exit;
}

if($o{'s'}) {
  &show_bundles();
  exit;
}

if($o{'w'}) {
  &all_html();
  exit;
}

my $group;
if($o{'g'}) {
  $group=$o{'g'};
  my $groups_dir=$dirs->{'groups'};
  my $target_dir="$groups_dir/$group";
  if(not -d $target_dir) {
    print "I don't see your group $group in $groups_dir";
    exit;
  }
  &build_bundles($group);
  &build_index($group);
  exit;
}


&build_bundles();
&build_index();
exit;

sub clear {
  my @dirs_to_clean=($settings{'bundles_xml'},
		     $dirs->{'bundles_pub'},
		     $dirs->{'bundles_cro'},
		     $dirs->{'bundles_dis'},
		     $dirs->{'bundles_cit'});
  if($o{'p'}) {
    @dirs_to_clean=($dirs->{'analysis_xml'},
		    $dirs->{'analysis_pub'},
		    $dirs->{'analysis_cro'},
		    $dirs->{'analysis_dis'},
		    $dirs->{'analysis_cit'});
  }
  foreach my $dir (@dirs_to_clean) {
    if(not $dir) {
      next;
    }
    if(not -d $dir) {
      next;
    }
    system("find $dir -type f -delete");
  }
}

## essentially just for testing the inject of spadis
sub inject_spadiss {
  if(not $spadis) {
    ## FixMe: not dependent on production version
    $spadis=&Cec::Store::load($files->{'spadis_json'})
      // confess "I don't see the spadis.";
  }
  print Dumper $spadis;
  #foreach my $file (shuffle glob($settings{'bundles_xml'}.'/*.xml')) {
  #  my $bana=basename($file);
  #  if(not $bana=~m|^[a-zA-Z0-9]{6}\.xml$|) {
  #    next;
  #  }
  #  &inject_spadis($file);
  #}
}

## essentially just for testing the inject of citers
sub inject_citers {
  ## global variable, but set here
  if(not $citer_sheet) {
    $citer_sheet=&Cec::Xslt::get_sheet('citer');
  }
  my $in_dir=$settings{'bundles_xml'};
  if($o{'p'}) {
    $in_dir=$dirs->{'analysis_xml'};
  }
  foreach my $file (shuffle glob($in_dir.'/*.xml')) {
    my $bana=basename($file);
    if(not $bana=~m|^[a-zA-Z0-9]{6}\.xml$|) {
      next;
    }
    &inject_citer($file);
  }
}

sub all_html {
  foreach my $web_type (@web_types) {
    if(not $web_sheet->{$web_type}) {
      my $name=$web_type.'_bundle';
      $web_sheet->{$web_type}=&Cec::Xslt::get_sheet($name);
    }
  }
  my $in_dir=$settings{'bundles_xml'};
  if($o{'p'}) {
    $in_dir=$dirs->{'analysis_xml'};
  }
  foreach my $file (shuffle glob($in_dir.'/*.xml')) {
    my $bana=basename($file);
    if(not $bana=~m|^([a-zA-Z0-9]{6})\.xml$|) {
      next;
    }
    if(not -f $file) {
      confess "I don't see your file '$file'.";
    }
    my $bunshid=$1;
    print "I do $bunshid\n";
    &html($bunshid);
  }
}

## essentially just for testing the inject of citers
sub inject_crorfs {
  ## global variable, but set here
  #if(not $citer_sheet) {
  #  $citer_sheet=&Cec::Xslt::get_sheet('citer');
  #}
  if(not $crorf) {
    $crorf=&Cec::Store::load($files->{'crorf_json'})
      // confess "I don't see the crorf.";
  }
  if(not $bx) {
    $bx=&Cec::Store::load($files->{'bundex_json'})
      // confess "I don't see the bundles index.";
  }
  my $in_dir=$settings{'bundles_xml'};
  if($o{'p'}) {
    $in_dir=$dirs->{'analysis_xml'};
  }
  foreach my $file (shuffle glob($in_dir.'/*.xml')) {
    my $bana=basename($file);
    if(not $bana=~m|^([a-zA-Z0-9]{6})\.xml$|) {
      next;
    }
    my $bunshid=$1 or confess "I need this here.";
    print "I do $file\n";
    &inject_crorf($file,$bunshid);
  }
}

sub inject_crorf {
  my $in=shift;
  my $bundle_doc=$in;
  my $bunshid;

  if(ref($in) eq 'XML::LibXML::Document') {
    $bunshid=shift // confess "If you give me a doc, I need a bunshid.";
  }
  else {
    my $bundle_file=$in;
    if(not -f $bundle_file) {
      confess "I don't see your file '$bundle_file'.";
    }
    $bundle_doc = XML::LibXML->load_xml(location => $bundle_file);
  }

  my $crorfs_ele=$bundle_doc->createElement('crorfs');
  $crorfs_ele->appendText("\n");
  my $ref_xp='/bundle/ref';
  my @ref_eles=$xpc->find($ref_xp,$bundle_doc)->get_nodelist();
  my $crorfs;
  foreach my $ref_ele (@ref_eles) {
    my $found_in=$ref_ele->getAttribute('found_in');
    my $start=$ref_ele->getAttribute('start');
    my $refid=$found_in.'+'.$start;
    if($crorf->{$refid}) {
      foreach my $refid (keys %{$crorf->{$refid}}) {
	if(not $crorfs->{$refid}) {
	  $crorfs->{$refid}=1;
	}
	else {
	  $crorfs->{$refid}++;
	}
      }
    }
  }
  if(not scalar (keys %$crorfs)) {
    print "I found no crorfs\n";
    return $bundle_doc;
  }
  foreach my $refid (keys %$crorfs) {
    my $crorf_ele=$bundle_doc->createElement('crorf');
    $crorf_ele->setAttribute('refid',$refid);
    my $found_in=$refid;
    $found_in=~s|\+(\d+)$||;
    my $start=$1;
    if(not $start) {
      print "I don't see a start on $refid.";
      next;
    }
    my $bx_found=$bx->{$refid};
    if($bx_found) {
      print "$found_in is in $bx_found\n";
      $crorf_ele->setAttribute('bundle',$bx_found);
    }
    else {
      print "I have no indexed bundle for $refid\n";
    }
    my $found_ref_ele=&Cec::Recitex::reference_by($found_in,$start,'start');
    #print $found_ref_ele;
    if(ref $found_ref_ele) {
      $crorf_ele->appendChild($found_ref_ele);
    }
    $crorf_ele->appendText("\n");
    $crorfs_ele->appendChild($crorf_ele);
    $crorfs_ele->appendText("\n");
  }
  my $bundle_ele=$bundle_doc->documentElement;
  ## remove existing crorf
  foreach my $old_crorfs_ele ($bundle_ele->getElementsByTagName('crorfs')->get_nodelist) {
    $old_crorfs_ele->parentNode->removeChild($old_crorfs_ele);
  }
  $bundle_ele->appendChild($crorfs_ele);
  $bundle_doc->documentElement->appendText("\n");
  ## if we get a file, let's save it
  if(not ref($in) and -f $in) {
    $bundle_doc->toFile($in);
  }
  ## we need that if we are called by build_bundle
  return $bundle_doc;
}

sub inject_citer {
  ## doc or file name
  my $in=shift;
  my $bundle_doc=$in;
  if(not ref($in) eq 'XML::LibXML::Document') {
    my $bundle_file=$in;
    if(not -f $bundle_file) {
      confess "I don't see your file '$bundle_file'.";
    }
    $bundle_doc = XML::LibXML->load_xml(location => $bundle_file);
  }
  my $ref_xp='/bundle/ref';
  my @ref_eles=$xpc->find($ref_xp,$bundle_doc)->get_nodelist();
  foreach my $ref_ele (@ref_eles) {
    my $found_in=$ref_ele->getAttribute('found_in');
    #print "$found_in\n";
    my $meta_file=&Cec::Meta::file($found_in);
    if(not $meta_file) {
      print "I don't see a meta file for $found_in\n";
      next;
    }
    my $meta_doc;
    eval {
      $meta_doc=XML::LibXML->load_xml(location => $meta_file);
    };
    if(not $meta_doc) {
      print "I can't load $meta_file\n";
      next;
    }
    my $citer_ele=&Cec::Xslt::transform($meta_doc,$citer_sheet)->documentElement();
    $ref_ele->appendChild($citer_ele->cloneNode(1));
    $ref_ele->appendText("\n");
  }
  ## if we got a file, let's save it
  if(not ref($in) and -f $in) {
    $bundle_doc->toFile($in);
  }
  ## we need that if we are called by build_bundle
  return $bundle_doc;
}

sub bunshid_from_file {
  my $file=shift;
  my $bana=basename($file);
  if(not $bana=~m|^([a-zA-Z0-9]{6})\.xml$|) {
    confess "You file $file does not look like a bundle file.";
  }
  my $bunshid=$1;
  return $bunshid;
}

sub show_bundles {
  my $r_list = retrieve $settings{'r_list'};
  print Dumper $r_list;
}

sub build_bundles {
  my $group=shift // '';
  my $r_list;
	my %atyd2n;
	my %r_refs;
  if($group) {
  	if($settings{'r_list'}) { $r_list=retrieve $settings{'r_list'}; }
    else { $r_list=&Cec::Groups::compile_papids($group); } #HASH 
  }
  else {
  	if(!$settings{'conf'}) {
    	die "I should not be here\n"; #prl: do not know why?!
		} 
    $r_list=retrieve $settings{'r_list'};#ARRAY
  }

  if($settings{'r_atyd2n'}) {
  	my %_atyd2n;
	  tie %_atyd2n, 'DB_File', $settings{'r_atyd2n'} or die;
		foreach my $k (keys %_atyd2n) {
			$atyd2n{$_atyd2n{$k}} = idkey($k);
		}
  }

	# <linking ...><reference ...> count for handle  (/pub/*.html page)
  if($settings{'r_refs'} && -f $settings{'r_refs'}) {
  	tie %r_refs, 'DB_File', $settings{'r_refs'} or die;
  }

	if(ref($r_list) eq 'ARRAY') {
		my $i_cnt = keys %atyd2n;
		my $cnt = @{$r_list};
		dbg($cnt." loaded from $settings{'r_list'}\n".$i_cnt." ids loaded from $settings{'r_atyd2n'}");
	}

  my $do_html=shift // '1';
  my $count_bundle=0;
  my $bundle;
  if($do_html) {
    foreach my $web_type (@web_types) {
      if(not $web_sheet->{$web_type}) {
				my $name=$web_type.'_bundle';
				$web_sheet->{$web_type}=&Cec::Xslt::get_sheet($name);
      }
    }
  }
  
  ## only required for build bundles, thus set here
  if(not $citer_sheet) {
    $citer_sheet=&Cec::Xslt::get_sheet('citer');
  }
  ## load crorf data
  if(not $crorf) {
  	dbg('loading '.$files->{'crorf_json'});
    $crorf=&Cec::Store::load($files->{'crorf_json'})
      // confess "I don't see the crorf.";
  }
  ## load bx data
  if(not $bx) {
  	dbg('loading '.$files->{'bundex_json'});
    $bx=&Cec::Store::load($files->{'bundex_json'})
      // confess "I don't see the bundles index.";
  }
  
  dbg($Cec::Groups::names);
  while($bundle=&Cec::Bundles::get($r_list,$count_bundle)) {
  	#me($bundle);
    $count_bundle++;
    ## something in this bundle?
    my @bundle_parts=@$bundle;
    if(not scalar @bundle_parts) {
      next;
    }
    ## some header bundle
    if(
    #not $group and
     $bundle->[0] eq 'lrn@handle') {
      #print "I skip\n";
      next;
    }

    if($o{'R'}) {
      if(not &repec_bundle_check($bundle)) {
				#print "I skip\n";
				next;
      }
    }

    if($settings{'series'}) {
      if(!series_check($bundle, $settings{'series'})) {
				#print "I skip\n";
				next;
      }
    }

    my $i_print=0;
    my $doc=XML::LibXML::Document->new('1.0','UTF-8');
    my $bundle_ele=$doc->createElement('bundle');
    $bundle_ele->appendText("\n");
    #my @sorted=sort @{$r_list->[$count_bundle-1]};
    #my $bundle_id=join('',@{$r_list->[$count_bundle-1]});
    #my $bundle_id=join('',@sorted);
    ## bundle short id
    #my $bunshid=&bunshid($bundle_id);
    my $bunshid;
    my $out_file;
    if($group) {
      my $name=$Cec::Groups::names->[$count_bundle-2]	// confess "I have no name for your bundle $count_bundle.".Dumper($Cec::Groups::names); # linked_papers, cited_papers, citing_papers
      $bunshid = $name;
      #$bunshid="$group:$name";
      #if(!-e $settings{'groups'}."/$group") { mkdir($settings{'groups'}."/$group"); }
      #$out_file=$settings{'groups'}."/$group/$name.bundle.xml";
      $out_file=&xml_file($bunshid);  #/home/prl/www/groups/Christopher-Baum/xml/citing_papers.xml
      # $bunshid: cited_papers   $name: cited_papers
    }
    else {
    	if(%atyd2n) { 
    		$bunshid=$atyd2n{$count_bundle-1};
    	}
    	else {
      	#$bunshid=&Cec::Bundles::id($r_list->[$count_bundle-1]); #prl: id deleted from Cec::Bundles, using local copy:
      	$bunshid=id($r_list->[$count_bundle-1]);
      }
      $out_file=&xml_file($bunshid);
    }

    #print `find ~/bundles/ -name '$bunshid*'`;
    if($o{'r'} and $bunshid ne $o{'r'}) {
      next;
    }
    $bunshids->{$bunshid}=1;
    $bundle_ele->setAttribute('bunshid',$bunshid);
    
    #if($group) {my $name=$Cec::Groups::names->[$count_bundle-1] // confess "I need this here.";$out_file=$Cec::Paths::dirs->{'groups'}."/$group/$name.bundle.xml";}else {$out_file=&xml_file($bunshid);}
    if(not $group) {
      my $size=&count_distinct_found_ins($bundle);
      if($o{'m'} and ($size < $o{'m'})) {
			#print "I skip bundle of size $size\n";
			next;
      }
    }

    ## don't make them again if newer than component file
    my $i_have_to_renew=1;
    if(-f $out_file) {
      $i_have_to_renew=0;
      foreach my $refid (@{$bundle}) {
				if($i_have_to_renew) {
				  next;
				}
				$refid=~m|(\d+)@(.*)@(\d*)$| or confess "I can't parse refid $refid";
				my $found_in=$2;
				my $cite_file=&Cec::Recitex::file($found_in) or next;
				if(-M $cite_file < -M $out_file) {
				  print "I have to renew $out_file because $cite_file is newer.\n";
				  $i_have_to_renew=1;
				}
      }
      foreach my $refid (@{$bundle}) {
				if($i_have_to_renew) {
				  next;
				}
				$refid=~m|(\d+)@(.*)@(\d*)$| or confess "I can't parse refid $refid.";
				my $found_in=$2;
				my $meta_file=&Cec::Meta::file($found_in) or next;
				if(-f $meta_file and -M $meta_file < -M $out_file) {
				  print "I have to renew $out_file because $meta_file is newer.\n";
				  $i_have_to_renew=1;
				}
      }
    }
    #elsif($i_have_to_renew) {
    #  exit;
    #}

    if(not $i_have_to_renew) {
      print "I skip the renewal of $out_file. do_html? $do_html\n";
      if($do_html) {
				&html($bunshid);
      }
      next;
    }
    
    ## a cache
    my $founds_in={};
    my $count_add=0;
#$o{'m'}=0;
    foreach my $refid (@{$bundle}) {
      if($o{'m'} and scalar(@{$bundle}) <  $o{'m'}) {
				next;
      }
      if(not $refid=~m|(\d+)@(.*)@(\d*)$|) {
				print "I can't parse refid '$refid'.\n";
				next;
	    }
	    
      #$output_string.=lc($refid);
      my $localnum=$1;
      my $found_in=$2;
      my $start=$3;
      my $ref_ele=$doc->createElement('ref');
      $ref_ele->setAttribute('found_in',$found_in);
      if($founds_in->{$found_in}) {
				print "I repeat $found_in.\n";
      }
      $founds_in->{$found_in}=$found_in;
      $ref_ele->setAttribute('num',$localnum);
      $ref_ele->setAttribute('start',$start);
      $ref_ele->setAttribute('refs',$r_refs{$found_in});
      $ref_ele->appendText("\n");
      #my $file=&Cec::Recitex::file($found_in) or next;
      #my $in_doc = XML::LibXML->load_xml(location => $file);
      ##print $in_doc;
      #my $ref_xp='//reference[@'."num='$localnum']";
      #my $found_ref_ele=$xpc->find($ref_xp,$in_doc)->[0];
      #if(not $found_ref_ele) {
      #print "No $ref_xp in $file.\n";
      #next;
      #}
      my $file=&Cec::Recitex::file($found_in);
      $file = $dirs->{'groups'}."/$group/$bunshid.packet.xml" if $group; 
      if(not $file || !-e $file) {
      	print "I see no file for $found_in";
      	next;
      }
      my $in_doc = XML::LibXML->load_xml(location => $file);
      my $found_ref_ele=&Cec::Recitex::reference_by($in_doc,$localnum,'num');
      if(not $found_ref_ele) {
      	print "I find no reference element in $file with number $localnum for $found_in.\n";
      	next;
      }
      ## find the futli we are getting the reference from
      my $futli_eles=$xpc->find("../../../../..",$found_ref_ele);
      if(not $futli_eles) {
      	print "I don't see an element futli in $file\n";
      }
      my $futli_ele=$futli_eles->[0];
      if(not $futli_ele->nodeName eq 'futli') {
      	warn "I don't see an element futli in $file\n";
      }
      my $futli_url=$futli_ele->getAttribute('url') // '';
      $ref_ele->appendChild($found_ref_ele->cloneNode(1));
      if($futli_url) {
      	$ref_ele->setAttribute('futli',$futli_url);
      }
      $ref_ele->appendText("\n");
      ##
      #my $show_file=
      #my $intref_xp='//intextref[/Reference[text()='.$localnum.']]';
      my $intref_xp='//intextref[Reference[text()='.$localnum.']]';
      my @intref_eles=$xpc->find($intref_xp,$in_doc)->get_nodelist();
      if(not scalar @intref_eles) {
      	#print "No $intref_xp in $file.\n";
      	#next;
      }
      foreach my $ele (@intref_eles) {
      	$ref_ele->appendChild($ele);
      	$ref_ele->appendText("\n");
      }
      $bundle_ele->appendChild($ref_ele);
      $count_add++;
      $bundle_ele->appendText("\n");
      #print $bundle_ele;
    }
    #if($count_add < $size) {
    #  die "I added $count_add fewer than the bundle size $size.";
    #}
    if(not scalar(@{$bundle})) {
      print "I reached the last at $count_bundle\n";
      last;
    }
    if(not $xpc->find('*',$bundle_ele)->size()) {
      print "I see nothing in $bundle_ele";
      next;
    }
    $doc->setDocumentElement($bundle_ele);
    $doc=&inject_citer($doc,$bunshid);
    $doc=&inject_crorf($doc,$bunshid);
    $doc->toFile($out_file);
    if($do_html) {
      &html($bunshid,$doc);
    }
    print "I write $out_file\n";
  }
}

sub check_for_repec {
}


sub xml_file {
  my $bunshid=shift // confess "I need a bunshid here.";
  my $out_file=$settings{'bundles_xml'}."/$bunshid.xml";
  if($o{'p'}) {
    $out_file=$dirs->{'analysis_xml'}."/$bunshid.xml";
  }
  return $out_file;
}

sub html {
  my $bunshid=shift // confess "I need a bunshid here.";
  my $doc=shift // '';
  
  my $params;
  if($settings{'r_refs'} && -f $settings{'r_refs'}) {
  	$params->{'showrefs'}="'1'";
  }
  
  ## called to renew a document after it is first written
  if(ref($doc) eq 'XML::LibXML::Document') {
    foreach my $web_type (@web_types) {
    	#dbg($settings{'bundles'."_$web_type"}.' ---- '.$bunshid . ' === '.$web_type);
      my $out_file=$settings{'bundles'."_$web_type"}."/$bunshid.html";
      if($o{'p'}) {
				$out_file=$dirs->{'analysis'."_$web_type"}."/$bunshid.html";
      }
      my $in_dir=$settings{'bundles_xml'};
      if($o{'p'}) {
				$in_dir=$dirs->{'analysis_xml'};
      }
      ## don't look at the modification times here
      my $out=&Cec::Xslt::transform($doc,$web_sheet->{$web_type},$params);
      &Cec::Xml::install_doc($out,$out_file);
      print "I install $out_file from doc object.\n";
    }
    return 1;
  }
  
  ## check on an older document
  foreach my $web_type (@web_types) {
    my $in_file=&xml_file($bunshid);
    my $doc=XML::LibXML->load_xml(location => $in_file);
    if(not -f $in_file) {
      ## this should not happen, but let's just return silently for now
      confess "I don't see your file '$in_file'.";
      return 0;
    }
    my $out_file=$settings{'bundles'."_$web_type"}."/$bunshid.html";
    if($o{'p'}) {
      $out_file=$dirs->{'analysis'."_$web_type"}."/$bunshid.html";
    }
    if(-f $out_file and -M $out_file < -M $in_file) 
    {
      print "I don't need to renew $out_file over $in_file\n";
      next;
    }
    my $out=&Cec::Xslt::transform($doc,$web_sheet->{$web_type},$params);
    &Cec::Xml::install_doc($out,$out_file);
    print "I installed $out_file\n";
  }
}

sub get_phase {
  my ($id, $jdata) = @_;
  my $w = 'none';
  if($jdata->{$id}) {
    my @phs = @{$jdata->{$id}->{'2norm'}};
    #my @ors = @{$jdata->{$id}->{'3orig'}};
    if(@phs) {
      $w = $phs[0]->{'w'}.' ('.$phs[0]->{'n'}.'/'.$phs[0]->{'t'}.')'; #.@phs.'-'.@ors;
    }
  }
  return $w;
}

sub get_topic {
  my ($id, $jdata) = @_;
  my $w = 'none';
#  print " $id".Dumper($jdata->{$id});
  if($jdata->{$id}) {
    my @phs = @{$jdata->{$id}->{topics}}; # ->[0] ?
    if(@phs) {
      $w = $phs[0]->{'topic'};
    }
  }
  return $w;
}

sub get_adist {
  my ($id, $jdata) = @_;
  if($jdata->{$id}) {
      my $float = $jdata->{$id}->{'average_cosine_distance_use_tfidf'} * 1000;
      return int($float + $float/abs($float*2 || 1));
  }
}


sub build_index {
	my $group = shift;
  my $doc=XML::LibXML::Document->new('1.0','UTF-8');
  my $bundles_ele=$doc->createElement('bundles');
  $bundles_ele->setAttribute('limit',$o{'m'});
  my @in_files=glob($settings{'bundles_xml'}."/*.xml");
  if($o{'p'}) {
    @in_files=glob($dirs->{'analysis_xml'}."/*.xml");
  }
  
  ## spadis summary
  my $dissum=&Cec::Store::load($settings{'dis_summary'})
    // confess "I don't see the spadis summary.";
  my $json = &File::Slurper::read_text($settings{'www_w2v_grams_json'});
  my $jdata = decode_json($json);
  my $json_t = &File::Slurper::read_text( $settings{'www_w2v_json'} );
  my $jdata_t = JSON::XS->new->decode ($json_t); # = decode_json($json_t);
  #me(ref($jdata_t ));
  my $json_i = &File::Slurper::read_text($dirs->{'www_w2v'}.'/average_cosine_distance.json');
  $json_i =~ s/ NaN/0.999/mgi;
  my $jdata_i = JSON::XS->new->decode($json_i);
  foreach my $in_file (shuffle @in_files) {
    my $bana=basename($in_file);
    #print "I index $bana\n";
    my $bunshid;
    if($group) {
    	$bunshid = substr($bana,0,length($bana)-4);
    } else {
	    if(not length($bana)==10) {
	      next;
	    }
	    $bunshid=substr($bana,0,6);
  	}
  	
    #if(defined($bunshids) and not $bunshids->{$bunshid}) {
    #  print "I remove $in_file\n";
    #  next;
    #}
    my $in_doc = XML::LibXML->load_xml(location => $in_file);
    my $bundle_ele=$doc->createElement('bundle');
    $bundle_ele->setAttribute('bunshid',$bunshid);
    #print $in_doc;
    my $i_add=0;
    ## moved this ahead to make an npub check

    my $npub=clean($xpc->findvalue("count(//ref)",$in_doc));
    if($o{'m'} and ($npub < $o{'m'})) {
      #print "I skip bundle of size $size\n";
      next;
    }
    $bundle_ele->setAttribute('npub',$npub);
    
    if($group) { $bundle_ele->setAttribute('title',$bunshid); $i_add=1; }
    else {
    	foreach my $field ('author','title','year') {
      	my $field_xp='/bundle/ref[1]/reference[1]/@'.$field;
      	my $value=clean($xpc->findvalue($field_xp,$in_doc));
      	if($value) {
					$bundle_ele->setAttribute($field,$value);
					$i_add=1;
				}
      }
    }
    if($i_add) {
      #$bundles_ele->appendText("\n");
      $bundles_ele->appendChild($bundle_ele);
    }
    my $ncit=clean($xpc->findvalue("count(//intextref)",$in_doc));
    $bundle_ele->setAttribute('ncit',$ncit);
    if($i_add) {
      #$bundles_ele->appendText("\n");
      $bundles_ele->appendChild($bundle_ele);
    }
    
    my $ncro;
    if(!$group) {
    	$ncro=clean($xpc->findvalue("count(//crorf)",$in_doc));
    } else {
    	$ncro=clean($xpc->findvalue("count(//intextref/Reference)",$in_doc))-$ncit;
  	}
  	$bundle_ele->setAttribute('ncro',$ncro);
    
    if($i_add) {
      #$bundles_ele->appendText("\n");
      $bundles_ele->appendChild($bundle_ele);
      $bundles_ele->appendText("\n");
    }
    my $ndis=$dissum->{$bunshid} // '';
    if($ndis) {
      $bundle_ele->setAttribute('ndis',$ndis);
    }
    my $phase=&get_phase($bunshid,$jdata);
    if($phase) {
      $bundle_ele->setAttribute('phrase',get_phase($bunshid,$jdata));
    }
    else {
      print "I have no phase for $bunshid\n";
    }
    
    my $topic=&get_topic($bunshid,$jdata_t);
    if($topic) {
      $bundle_ele->setAttribute('topic',get_topic($bunshid,$jdata_t));
    }
    else {
      print "I have no topic for $bunshid\n";
    }
    my $adist=&get_adist($bunshid,$jdata_i);
    if($adist) {
      $bundle_ele->setAttribute('adist',get_adist($bunshid,$jdata_i));
    }
    else {
      print "I have no adist for $bunshid\n";
    }
    if($i_add) {
      #$bundles_ele->appendText("\n");
      $bundles_ele->appendChild($bundle_ele);
    }
  }
  $doc->setDocumentElement($bundles_ele);
  if($o{'p'}) {
    $doc->toFile($dirs->{'analysis'}."/index.xml");
  }
  else {
    $doc->toFile($settings{'bundles'}."/index.xml");
  }
  my $pretty_today=&Cec::Dates::pretty_today;
  my $params;
  if($o{'R'}) {
    $params->{'type'}="'repec'";
  }
  $params->{'conf'}="'$settings{'conf'}'";
  if($settings{'self_url'}) { $params->{'self_url'}="'$settings{'self_url'}'"; }
  $params->{'date_pretty'}="'$pretty_today'";
  my $out_file=$settings{'bundles'}."/index.html";
  if($o{'p'}) {
    $out_file=$dirs->{'analysis'}."/index.html";
  }
  my $out=&Cec::Xslt::transform($doc,'bundle',$params);
  print "I am done with the tranform, I start installation ... ";
  &Cec::Xml::install_doc($out,$out_file);
  print "done\n";
}

sub bunshid {
  my $in=shift // confess "I need this defined.";
  $md5->add($in);
  my $out=$md5->b64digest();
  $out=~s|\+||g;
  $out=~s|/+||g;
  $out=substr($out,0,6);
  return $out;
}

sub count_distinct {
  my $ins=shift;
  my $seen={};
  if(not ref($ins) eq 'ARRAY') {
    confess "I need an arryref here.";
  }
  foreach my $in (@$ins) {
    if($seen->{$in}) {
      next;
    }
    $seen->{$in}=1;
  }
  my $total=scalar keys %$seen;
  return $total;
}

sub count_distinct_found_ins {
  my $ins=shift;
  ## debug stuff
  #if(scalar @$ins > 2) {
  #  print Dumper $ins;
  #  die;
  #}
  my $seen={};
  if(not ref($ins) eq 'ARRAY') {
    confess "I need an arryref here.";
  }
  foreach my $in (@$ins) {
    if($in eq 'lrn@'.'handle') {
      next;
    }
    $in=~m|^(\d+)@(.*)@(\d*)$| or confess "I can't parse refid $in";
    my $found_in=$2;
    if($seen->{$found_in}) {
      next;
    }
    $seen->{$found_in}=1;
  }
  my $total=scalar keys %$seen;
  return $total;
}

## changes global $dirs
sub repec_dirs {
  foreach my $name (keys %$dirs) {
    if(not $name=~m|^bundles|) {
      next;
    }
    my $repec_name='repec_'.$name;
    $dirs->{$name}=$dirs->{$repec_name};
  }
}

sub repec_bundle_check {
  my $in=shift;
  if(not ref($in) eq 'ARRAY') {
    confess 'I need an arrayref here.';
  }
  foreach my $refid (@$in) {
    if(not $refid=~m|\d+@([^@]+)@\d+$|) {
      print "This is a bad refid: $refid\n";
      return 0;
    }
    my $papid=lc($1);
    if(not $papid=~m|^repec|) {
      return 0;
    }
    if($papid=~m|^repec:rus|) {
      return 0;
    }
  }
  #print Dumper $in;
  return 1;
}

sub clean {
  my $in=shift;
  $in=~s|\s+| |g;
  $in=~s|^\s+||;
  $in=~s|\s+$||;
  return $in;
}

# id from  Cec::Bundles::id :
sub id {
  my $b=shift // confess "I need this defined.";
  if(not ref($b) eq 'ARRAY') {
    confess "I need an arrayref here.";
  }
  my @sorted=sort @{$b};
  my $id=join('',@sorted);
  $md5->add($id);
  my $out=$md5->b64digest();
  $out=~s|\+||g;
  $out=~s|/+||g;
  $out=substr($out,0,6);
  return $out;
}




# prl subs:



sub mkdirs
{
	my %set = %{$_[0]};
	my $bdir = $set{'base_dir'};
	
	if($bdir) {
		if($set{'bundles_dir'} && !-e $set{'bundles_dir'}) { mkdir $set{'bundles_dir'}; }
		if($set{'groups'} && !-e $set{'groups'}) { mkdir $set{'groups'}; }
		foreach my $d (keys %set) {
			if($set{$d} =~ /^$bdir/ && !-e $set{$d}) { mkdir $set{$d}; }
		}
	}
}

sub get_series {
	my $lang = shift; 
	my $dir = shift;
	my $file = $dir.'/A-list';
	my $login = getlogin();
	my $data;
	
	if($login eq 'prl') { 
		# get from local
		$data = `cat $file`;
	} else {
		# cec user take from socionet.ru (see langs_series.py)
		$data = `ssh cyrcitec\@socionet.ru cat A-list`;
	}
	my $series;
	my @lines = split(/\n/, $data);
	foreach my $line (@lines) {
		my @parts = split(/\s+/, $line);
		if( (scalar @parts == 2 && $lang eq 'en') || (scalar @parts == 3 && $lang ne 'en') )
			{ push @$series, $parts[0]; }
	}
	return $series;
}

sub series_check {
	my ($in, $series) = @_;
	if(not ref($in) eq 'ARRAY') {
    foreach my $ser (@$series) {
    	if($in =~ /^\d+\@$ser:/) { return 1; }
    }
    return 0;
  } else {
	  foreach my $refid (@$in) {
	    if(series_check($refid, $series)) { return 1; }
	  }
	  return 0;
	}
  
}
sub idkey {
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