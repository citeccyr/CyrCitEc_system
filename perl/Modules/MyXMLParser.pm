#                                                                              #
#                                    MyXMLParser                               #
#  		                     Package made by prl@mail.ru		                     #
#	                                     2004 			                             #
#                                                                              #
package MyXMLParser;

# usage: $parser = new MyXMLParser('inputfile' => "/usr/home/socionet/public_html/cgi/xml/bad_xml_files!/ee.xml"); 
# die $parser->GetHashFromXmlFile();


#use MyCommon; # qw(GetFileContent prepareXML removeWS re);
use strict;
use Data::Dumper;
use Tie::IxHash;
#use main;

##############################################################################
# Define some constants
##############################################################################
use vars qw(@ISA $VERSION @EXPORT); 

@ISA 	= qw(Exporter);
@EXPORT = qw(GetHashFromXmlFile); #qw(XMLin GetHashFromXmlFile XMLout);
$VERSION = "1.2";


# params from input here:
my %params;
# params for output here:
my %outparams;
# parsed info:
my %this = Tie::IxHash->new();
# for XMLMakeSimpleHash:
my $attrtolower = 0;

BEGIN
{
	
}
sub test
{
	#local *c = $main::users_documents_dir;
	#print $c;
	#print *$main;
	#$this_pack = __PACKAGE__;
	# $that_pach = caller();
	#print "===".$main::users_documents_dir."==";
}
sub XMLin
{
  	my $self;
  	if($_[0]  and  UNIVERSAL::isa($_[0], 'MyXMLParser')) { $self = shift; }
  	else { $self = new MyXMLParser(); 
  		if(!-e $_[0]) { die "counld not find " .$_[0]." file MyXMLParser from ".caller(); };
  		$self->param('inputfile', $_[0]);
  	}
  	my $file = shift;
	my $c = @_/2;
	for(my $i = 0; $i < $c; $i++) {	my ($k,$v) = (shift, shift); $self->param($k, $v); }
	return $self->GetHashFromXmlFile('inputfile' => $file);
}

sub XMLout
{
  	#my $xm = shift;
  	my $self;
  	if($_[0]  and  UNIVERSAL::isa($_[0], 'MyXMLParser')) { $self = shift; }
  	else { $self = new MyXMLParser(); $self->outparam('outputfile', shift); }
	my $c = @_/2;
	for(my $i = 0; $i < $c; $i++) {	my ($k,$v) = (shift, shift); $self->outparam($k, $v); }
	if($self->outparam("hash") ne "") { $this{'hash'} = $self->outparam("hash"); }
	if($self->outparam("withOrder") ne "") { $self->param('withOrder', $self->outparam("withOrder")); }
	#die Dumper($self->outparam("hash"));
	if($self->param('withOrder')) { $this{'outxml_content'} = $self->MakeContentFromHashWithOrder(  ); }
	else { $self->MakeContentFromHash(); }

	my $decl = $self->outparam("xmldecl");
	if($decl eq "") { $decl = $this{'headers'}; }

  	if($self->outparam('outputfile') ne "") { 
  		
  		if($self->outparam('outputfile') eq "/usr/home/spz/public_html/crossdb/cross.xml")
		{
			#die $self->outparam('outputfile')."==\n".$decl.$this{'outxml_content'};
		}
		#die $this{'outxml_content'};
  		SaveFileContent($self->outparam('outputfile'), $decl.$this{'outxml_content'}); 
  	}
}
sub new {
	my $self = shift;
	%params = ();
	my $c = @_/2;
	for(my $i = 0; $i < $c; $i++) { $self->param(shift,  shift); }
	$self->Init();
	return $self;
}

sub Init()
{
	my $self = shift;
	#require "/usr/home/spz/public_html/cgi/MyXMLSimple.pm";
	#die Dumper(MyXMLSimple::XMLin("/usr/home/socionet/public_html/cgi/xml/bad_xml_files!/simple.xml", "keeproot" => 1, forcearray => 1, encoding => 'cp1251', keyattr => {}));
	#my $file = @_[0];
	$this{'error'} = "";
}

sub GetHashFromXmlFile
{
	my $self = shift;
	my $c = @_/2;
	for(my $i = 0; $i < $c; $i++) {
		$self->param(shift,  shift);
	}
	#my $content;
#	if($self->param('test')) { die $self->param('inputfile'); }
	if($self->param('inputfile') ne "") { 
		if(!-e $self->param('inputfile')) { die "Could not find file ".$self->param('inputfile')." in ".caller()." func GetHashFromXmlFile"; }
		$this{'content'} = GetFileContent($self->param('inputfile'),$self->param('fileencoding')); }
	elsif($self->param('content') ne "") { $this{'content'} = $self->param('content'); }
	#print STDERR 'HI ---'.$self->param('fileencoding');
	#my $headers;
	#if($self->param('test')) {die $this{'content'};}
	my($headers, $content) = $self->splitHeaders();

	$this{'headers'} = $headers;
	$this{'xml_content'} = $content;
	
	$content = $self->removeComments($content);
	$content = $self->prepareXML($content);

	#$content = "<root><a b=\"c\">d</a><e f=\"g\">M</e></root>";
	
	if($self->param('withOrder')) { 
		my @dd = $self->splitPartsSorted($content);
		$this{'hash'} = \@dd; }
	else { $this{'hash'} = $self->splitParts($content); }
	#if($self->param('test')) { die Dumper($this{'hash'}); }
	
	if($self->param('removearrays') == "1") { 
		$this{'hash'} = $self->RemoveArrays($this{'hash'}); 
	}
	#if($self->param('test')) { die Dumper($this{'hash'}); }
	return $this{'hash'};
}
sub GetParsedParam
{
	return $this{$_[0]};
}
sub GetXMLHeaders
{
	my $str = $this{'headers'};
	$str =~ s/></>\n </mg;
	if($str ne "") { $str .= "\n"; }
	return $str;
}
#my $oo=0;

sub splitPart
{
	#my $tt = "";
	#$oo++;
	my $self = shift;
	#$dgb++;
	my ($ins) = @_; #, $tagname)
#if($self->param('test')) {	die $ins; }
	my ($fpart, $spart, $attr, $content, $tagname);
#if($oo == 2) { die $ins; }
	if($ins =~ /^[\s]*<([\d\w:-]+)([^>]*)>/) {  # should be == isStringContent
	#if(!isStringContent($ins)) {
		$tagname = $1; 
#if($self->param('test')) { die "111".$tagname; }		
	  	$attr = $2; $attr =~ s/^[\s]*//; $attr =~ s/[\s]*$//; $attr =~ s/[\s]+/ /;
	   
		my @arr = split($tagname, $ins);
#if($self->param('test')) { die join("\n==========\n\n", @arr); }		
		my $cnt = 1;
		my @firstpart;
		my @secondpart;
		push @firstpart, shift @arr;
		#my $ii = @arr; if($oo == 1) { die "==".$ins."=="; }
		for(my $i = 0; $i < @arr; $i++) {
			my $elem = $arr[$i];
			my $nextelem = $arr[$i+1];
#$tt .= $cnt.": ".substr($elem, length($elem)-2, 2)."====". substr($elem, 0, 1)."    ";			
			if($cnt != 0) {
				
				if(substr($elem, length($elem)-2, 2) eq "</" && substr($nextelem, 0, 1) eq ">") { 
					
					$cnt--; 
				}
				elsif(substr($elem, length($elem)-1, 1) eq "<" && substr($nextelem, 0, 1) eq ">" ) { $cnt++; }
				push @firstpart, $elem; #shift @arr;
	
			} else {
				push @secondpart, $elem;
			}#else { die join("==", @firstpart); }
			#$tt .= $cnt."-";
		}
#if($self->param('test')) { die join("\n==========\n\n", @secondpart); }				
#if($oo == 1) { die $tt; }		
		#die join($tagname, @firstpart); #join("==",  @secondpart);
	if( $cnt ) { $this{'error'} = "Not valid XML content."; };
	 
	 	my @contarr = @firstpart; shift @contarr;
	 	$content = join($tagname, @contarr); $content =~ s/^([^>])*>//; $content =~ s/<\/$//; 
		$fpart = join($tagname, @firstpart).$tagname.">"; $fpart = removeWS($fpart);
#if($self->param('test')) { die join("\n==========\n\n", $content); }
		#die $fpart;
		$spart = join($tagname, @secondpart);  $spart =~ s/^>//; $spart = removeWS($spart);
		#die "==".$fpart."=".
		#die $spart;
		#print "\n------\n".$spart;
	} else { $content = $ins; }
	 #($tagname, $attr, $fpart, $content, $spart);
#if($self->param('test')) { die $content; }
#if($self->param('test')) { 
	$content =~ s/^[ \n\r\t]*</</mg; 
	$content =~ s/>[ \n\r\t]*$/>/mg; 
	$content =~ s/^[ \n\r\t]*$//mg; 
	#if($content =~ /^[ \n\r\t]*$/) { $content = ''; }
	return ($tagname, $attr, $fpart, $content, $spart);
}


sub splitParts
{
	my $self = shift;
	#$dbgs++;
	
	my ($ins) = @_;
	my @parts = $self->getParts($ins);	
	my $result;# = Tie::IxHash->new();

	for(my $i = 0; $i < @parts; $i++) {
	if($parts[$i] =~ /\w/) {
		
		my($t1, $a1, $f1, $c1, $s1) = $self->splitPart($parts[$i]);
#if($self->param('test')) {  my $rr= @parts; die Dumper($self->splitPart($parts[$i])); }
		if(!$self->isStringContent($c1)) {
			my $res = $self->splitParts($c1);
			if(ref($res) eq "HASH") { 
				if($a1 ne "") { 
					#die $a1."\n"; #die "df";
					my %att = $self->getAttributes($a1);
					foreach my $k (keys(%att))  {
						# putting attributes:
						$res->{$k} = $self->doEncode($att{$k}, $params{'encoding'}); 
					}
				}
				push @{$result->{$t1}}, $res; 
			}
		}
		else {
			# putting values:
#if($self->param('test')) { die "??".$a1."--t1:".$t1; }
			
			if($a1 ne "") { 
				
				my %ahs;
				my %att = $self->getAttributes($a1);
				$ahs{'content'} = $self->doEncode($c1, $params{'encoding'});
				foreach my $k (keys(%att))  {
					$ahs{$k} = $self->doEncode($att{$k}, $params{'encoding'}); 
				}
				#if($self->param('debug')) { print STDERR Dumper($result)."==".$t1."\n\n"; }
				push @{$result->{$t1}}, \%ahs;
			} else {
				#print STDERR $t1."==".ref($result)."==";
				#$result->{$t1} = ( $self->doEncode($c1, $params{'encoding'}) );
				push @{$result->{$t1}}, $self->doEncode($c1, $params{'encoding'}); 
			}
		}
	}	
	}
	return $result;
	
	
}

sub RemoveArrays
{
	my $self = shift;
	if(ref($_[0]) eq "HASH") {
		my %hs = %{$_[0]};
		#die Dumper(
		foreach my $k (keys(%hs)) {
			$hs{$k} = $self->RemoveArrays($hs{$k});
		}
		return \%hs;
	} elsif(ref($_[0]) eq "ARRAY") {
		my @arr = @{$_[0]};
		my @res = ();
		if(@arr == 1 && ref($arr[0]) ne "HASH" && ref($arr[0]) ne "HASH") {
			return $arr[0];
		} else {
			
			
			for(my $i = 0; $i < @arr; $i++) {
				push @res, $self->RemoveArrays($arr[$i]);
			}
		}
		return \@res;
	} else {
		return $_[0];
	}
}


sub MakeContentFromHashWithOrder
{
	my $self = shift;
	my $t = shift;
	if(!defined $t) { $t = $this{'hash'}; }
	my $level = shift;
	if(!defined $level) { $level = 0; }
	my $str = "";
	#print STDERR $level.Dumper($t)."\n\n";
	if($level == 5) { die ""; }
	if(ref($t) eq "ARRAY") { 
		my @arr;
		#if($level == 0) { die Dumper($t); }
		
		for(my $i = 0; $i < @{$t}; $i++) {
			my $cont = $self->MakeContentFromHashWithOrder(${$t}[$i], $level+1);
			push @arr, $cont;
		}
		$str = join("", @arr);
	}
	elsif(ref($t) eq "HASH") {
		my $nm = "";
		my $attr = "";
		my $cont;
		foreach my $key (keys(%{$t})) {
			if( ref($t->{$key}) eq "ARRAY") { $nm = $key; $cont = $t->{$key}; }
			else { $attr .= " ".$key."=\"".$self->prepareAttr($t->{$key})."\""; }
		}
		#if($attr ne "") { die Dumper($cont)."=="; }
		my $inc = "";
		if($cont ne "") { $inc = $self->MakeContentFromHashWithOrder($cont, $level); }
		if(($nm ne "" && $inc ne "") || ($attr ne "" && $nm ne "")) {
			my $tabs = "";
			for(my $i = 0; $i < $level; $i++) { $tabs .= "   "; }
			my $del = ""; my $tabse = "";
			if(ref($cont) eq "HASH" || (ref($cont) eq "ARRAY" && ref(${$cont}[0]) eq "HASH")) { $del = "\n"; $tabse = $tabs; }
			$str = $tabs."<".$nm.$attr.">".$del.$inc.$tabse."</".$nm.">\n";
		}
	} else {
		$str = $t;
	}
	return $str;
}
sub prepareAttr
{
	my $self = shift;
	my $t = shift;
	return $t;
}


sub MakeContentFromHash
{
	my $self = shift;
	my $t = shift;

	my $hs ;
	if(ref($t) ne "HASH") { $hs = $this{'hash'}; }
	else { $hs = $t; }
	 	#if($self->outparam('outputfile') eq "/usr/home/spz/public_html/crossdb/cross.xml")
		#{
		#	die Dumper($hs);
		#}
	#die Dumper($hs);
	my $str = $self->MakeContent($hs);
	if($str =~ /^>/) { $str = substr($str, 1, length($str)-1); }
	if($str =~ /<$/) { $str = substr($str, 0, length($str)-1); }

	$str = $self->unPrepareXML($str);

	$str = $self->FormatXML($str);

	$this{'outxml_content'} = $str;
	
	#my($headers, $content) = $self->splitHeaders();
	#$this{'headers'} = $headers;
	#$this{'xml_content'} = $content;
	
	return $str;
}

# ----------------------------- FOR SAVING ---------------------------
sub MakeContent
{
	my $self = shift;
	my $hs = shift;
	
	my $tg = shift;
	#my $rr = shift;
	#my $count = shift;
	
	my $out;
	if(ref($hs) eq "HASH") {
			if(!$self->haveSubNodes($hs)) {
				$out = ">".$hs->{'content'}."<";				
			}
			else #if(ref($hs->{$k}) eq "ARRAY") 
			{ 
				foreach my $k (keys(%{$hs})) {
					if(ref($hs->{$k}) eq "ARRAY") {
						$out .= $self->MakeContent($hs->{$k}, $k); 
					} else { #nothing? looks error ?
					}
				} # if last elem:
				if($tg ne "") {	$out = ">".$out."<"; }
			}
			$out = $self->getTagAttrs($hs).$out;
	} elsif(ref($hs) eq "ARRAY") {
		for(my $i = 0; $i < @{$hs}; $i++) {
			$out .= "<$tg";
			$out .= $self->MakeContent(@{$hs}[$i], $tg);
			$out .= "/$tg>";			
		}
	} else {
		return ">".$self->doEncode($hs, $outparams{'encoding'})."<";
	}
	return $out;
}
sub haveSubNodes
{
	my $self = shift;
	my $hs = shift;
	my $out = 0;
	if(ref($hs) eq "HASH") {
		foreach my $k (keys(%{$hs})) {
			if(ref($hs->{$k}) ne "" ) { $out = 1; } #|| $k eq "content"
		}
	}
	return $out; 
}
sub getTagAttrs
{
	my $self = shift;
	my $hs = shift;
	my $out = "";
	if(ref($hs) eq "HASH") {
		foreach my $k (keys(%{$hs})) {
			if(ref($hs->{$k}) eq "") {
				if($k ne "content") { $out .= " ".$k."=\"".$self->DecodeAttr($hs->{$k})."\""; }
			}
		}
	}
	return $out;
}
sub DecodeAttr
{
	my $self = shift;
	my $val = shift;
	$val =~ s/"/&quot;/mg; #"
	return $val;
}
sub EncodeAttr
{
	my $self = shift;
	my $val = shift;
	$val =~ s/&quot;/"/mg; #"
	return $val;
}
sub FormatXML
{
	my $self = shift;
	my $str = shift;
	my $out = "";
	my @arr = split("><", $str);
	my $cnt = 0;
	for(my $i = 0; $i < @arr; $i++)
	{	
		if(index(" ".$arr[$i],"/") != 1 && $i > 0) { $cnt += 3; } 
		if($i) { $out .= ">\n".nbsps($cnt)."<"; } 
		$out .= $arr[$i];
		if(index(" ".$arr[$i],"/") == 1 || substr($arr[$i],length($arr[$i])-1 ,1) eq "/" || index($arr[$i], "</") > 0 ) { $cnt -= 3; }	
	}
	return $out;
}
#-------------------------------------- END FOR SAVING ----------------------------

#------------------------------- SORTED HASH  -------------------------------------



sub splitPartsSorted
{
	my $self = shift;	
	my ($ins) = @_;
	
	my @parts = $self->getParts($ins);	
  my @resArr;
  
	for(my $i = 0; $i < @parts; $i++) {
	if($parts[$i] =~ /\w/) {
		my %ahs;
		my($t1, $a1, $f1, $c1, $s1) = $self->splitPart($parts[$i]);
		
		if(!$self->isStringContent($c1)) 
		{
			my @res = $self->splitPartsSorted($c1);			 
				if($a1 ne "") { 
					my %att = $self->getAttributes($a1);
					foreach my $k (keys(%att))  {
						# putting attributes:
						$ahs{$k} = $self->doEncode($att{$k}, $params{'encoding'}); 
					}
				}
				for(my $i = 0; $i < @res; $i++) { $ahs{$t1}->[$i] = $res[$i]; }
				push @resArr, \%ahs;			
		}	else {
			# putting values:			
			if($a1 ne "") { 
				my %att = $self->getAttributes($a1);
				foreach my $k (keys(%att))  {
					$ahs{$k} = $self->doEncode($att{$k}, $params{'encoding'}); 
				}
			}
			$ahs{$t1}->[0] = $self->doEncode($c1, $params{'encoding'});
			push @resArr, \%ahs;
		}
	}
	}
	return @resArr;
}


#---------------------------- END SORTED HASH -------------------------------------


#--------------------------------- WORKING WITH FILE IN USER DIR XML --------------
sub XMLMakeSimpleReplaceKeys
# join vars from XMLMakeSimpleHash:
{
	my $self = shift;
	my ($in, $ks) = @_;
	my %res;
	my %hs = %{$in};
	my %ikeys = %{$ks};
	foreach my $k (keys(%hs))
	{
		my $ke = $ikeys{$k};
		if(!in_array($k, (keys(%ikeys))) ) { 
			$res{$k} = $hs{$k};
		} elsif($ke ne "") {
			$res{$ke} = $hs{$k};
		}
	}
	return \%res;
}
sub XMLMakeRedifContent
{
	my $self = shift;
	my ($in) = @_;
	my %hs = %{$in};
	my $out;
	foreach my $k (keys(%hs))
	{
		my $str = $hs{$k};
		$str =~ s/^[\n\r\t]+//mgi;
		$str =~ s/[\n\r\t]+$//mgi;		
		$str =~ s/\n([^ ])/\n $1/g;
		$out .= $k.": ".$str."\n";
	}
	return $out;	
}

sub XMLMakeSordedRedifContent
{
	# NEED TO INMPLEMENT.
}

# for personal zone files parsing:
sub XMLMakeSimpleArray
# join vars from XMLMakeSimpleHash:
{
	my $self = shift;
	my ($in, $joinv) = @_;
	my %res;
	my %hs = %{$in};
	foreach my $k (keys(%hs))
	{
		$res{$k} = join($joinv, @{$hs{$k}});
	}
	return \%res;
}


sub XMLMakeSimpleHash
{
	my $self = shift;
	my $hs = shift;
	my $tg = shift;
	my $inar = shift;
	my @inar;
	my %res;
	if($inar ne undef) { @inar = @{$inar}; }
	
	my $usearr = 1;
	
	if(ref($hs) eq "HASH") {
			if(!$self->haveSubNodes($hs)) {
				#$out = ">".$hs->{'content'}."<"; #??
			}
			else
			{ 
				foreach my $k (keys(%{$hs})) {
					
					if(ref($hs->{$k}) eq "ARRAY") {
						my %out = %{$self->XMLMakeSimpleHash($hs->{$k}, $k, \@inar)};
						foreach my $j (keys(%out))
						{ 
							if(ref($out{$j}) eq "ARRAY") { 
								for(my $u = 0; $u < @{$out{$j}}; $u++) {
									push @{$res{$j}}, ${$out{$j}}[$u]; 
								}
							} else {
								push @{$res{$j}}, $out{$j}; 
							}
						}
					} else { #nothing
					}
				} # if last elem:
			}
	} elsif(ref($hs) eq "ARRAY") {
		for(my $i = 0; $i < @{$hs}; $i++) {
			if($tg ne "") { push @inar, $tg; }
			my %out = %{$self->XMLMakeSimpleHash(@{$hs}[$i], $tg, \@inar)};
			foreach my $j (keys(%out))
			{ 
				if(ref($out{$j}) eq "ARRAY") { 
					for(my $u = 0; $u < @{$out{$j}}; $u++) 
					{
						push @{$res{$j}}, ${$out{$j}}[$u]; 
					} 
				} else {
					push @{$res{$j}}, $out{$j}; 
				}
			}
			pop @inar;
		}
	} else {
		my $this_attr = join("-", @inar);
		if($attrtolower) { $this_attr = lc($this_attr); }
		$res{$this_attr} = $self->doEncode($hs, $outparams{'encoding'});
	}
	return \%res;
}

sub attrtolower
{
	my $self = shift;
	$attrtolower = shift;
}

sub XMLMakeSimpleJoinHash
{
	my $self = shift;
	my $xmls = shift;
	my $def = shift;
	my %res = ();
	my $tt = $self->XMLMakeSimpleHash($xmls);
	foreach my $key (keys(%$tt))
  {
  	my $del = $def->{$key}->{'Delimiter'};
  	if($def eq "") { $del = " "; }
  	$res{$key} = join($del, @{$tt->{$key}});
  }
	return \%res;
}

#----------------------------------------------------------------------------------


sub doEncode
{
	my ($self, $str, $enc) = @_;
	#if($self->param('inputfile') =~ /aoh/) { die $this{'headers'}; }
	my $xml_decl = lc($this{'headers'});
	$xml_decl =~ s/ //mg;
	if($enc eq "UW" && $xml_decl !~ /encoding="windows-1251"/) { return UW($str); }
	elsif($enc eq "WU" && $xml_decl !~ /encoding="utf-8"/) { return WU($str); }
	else { return $str; }
}
#my $rr = 0;
sub getParts
{
	#$rr++;

	my $self = shift;
	my ($ins) = @_;
	
	my @arr;
#if($rr ==2 ) { die $ins; }
	my($t, $a, $f, $c, $s, $isstr) = $self->splitPart($ins);
	push @arr, $f;
	
	while($s ne "") {
		my($t1, $a1, $f1, $c1, $s1) = $self->splitPart($s);
		push @arr, $f1;
		if($self->isStringContent($s1)&& (removeWS($s1) ne "")) { $this{'error'} = "Not Valid XML"; }
		$s = $s1;
	}
	#if($rr ==2 ) { die join("\n============\n\n", @arr); }
	return @arr;
}



sub getAttributes
{
	my $self = shift;
    my $str = $_[0];
    my %hs;
    my ($i1, $i2, $quo, $attr, $atval);
    while($str ne "") {
        $str = removeWS($str);
        $i1 = index($str, "=");
        $attr = substr($str, 0, $i1);
        $quo = substr($str,$i1+1,1);
        $str = substr($str,$i1+2,length($str)-$i1-2);
        $i2 = index($str, $quo);
        $atval = substr($str, 0, $i2);        
        if(($attr ne "") && ($atval ne "")) { $hs{$attr} = $self->EncodeAttr($atval); }
        $str = substr($str, $i2+1, length($str)-$i2);
    }
    return %hs;
}

sub splitHeaders
# return (header, content) header = "<?xml ....><?xml-stylesheet ..>..."
{
	my $self = shift;
	my $in = $this{'content'};
	my $head = "";
	while($in =~ /^([\s]*)(<\?[^>]*>)([\s]*)/) {
		$head .= $2;
		my $block = $1.$2.$3; $block =~ s/\?/\\?/g;
		$in =~ s/^$block//mg;		
	}
	return ($head, $in);
}

sub params
{
	return %params;
}
sub param 
{
	# get or set parametr
        my($self,@p) = @_;
        if(@p > 1) {
        	$params{$p[0]} = $p[1];
		
                #$self->{'param'}->{$p[0]} = $p[1];
        } else {
        	return $params{$p[0]};
                #return $self->{'param'}->{$p[0]};
        }
}


sub outparam 
{
	# get or set parametr
        my($self,@p) = @_;
        if(@p > 1) {
        	$outparams{$p[0]} = $p[1];
                #$self->{'param'}->{$p[0]} = $p[1];
        } else {
        	return $outparams{$p[0]};
                #return $self->{'param'}->{$p[0]};
        }
}


# ---------------------- Not main Specific functions -----------------
sub prepareXML_new # long time
{
	my $self = shift;
	my $in = $_[0];
	my $outStr = "";
	my $last = 0;
	my $nonEmp = 0;
	my $lstName = "";
	my $ended = 1;
	
	my $pos = 0; 
	#     <    nm      vl    =     "any"   /   >     </nm>
	#  0  1     3   9  5           6   7   8           4
	
	for(my $i = 0; $i < length($in); $i++)
	{		
		my $cur = substr $in,$i,1;

		if($cur eq "<") { 
			if($pos == 0) { $pos = 1; }
			if(!$ended) {  $outStr .= substr $in, $nonEmp+1, $i-$nonEmp-1; }
			$outStr .= "<";
		}
		elsif($cur eq ">") {  $outStr .= ">";
			if($pos == 8) { $outStr .= "</".$lstName.">"; }; $pos = 0; $nonEmp = $i; $ended = 1;
		}
		elsif($cur eq "/") { 
			
			if($pos == 3) { $lstName = substr $in, $nonEmp, $i-$nonEmp; $pos = 8; }
			elsif($pos == 7 || $pos == 9) { $pos = 8; }
			elsif($pos == 1) { $pos = 4; $outStr .= $cur; }
			
		}
		elsif($cur eq "=") { if($pos == 5) { $outStr .= $cur; } }
		elsif($cur eq '"') { 
			if($pos == 5) { $pos = 6; }
			elsif($pos == 6) { $pos = 7; } 
			$outStr .= $cur;
		}
		elsif($cur ne " " && $cur ne "\t" && $cur ne "\n" && $cur ne "\r") {
			
			if($pos == 1) { $pos = 3; $nonEmp = $i; $outStr .= $cur; }
			elsif($pos == 4) { $outStr .= $cur; $ended = 1; }
			elsif($pos == 0) { $ended = 0; }
			elsif($pos == 3) { $outStr .= $cur; }
			elsif($pos == 7 || $pos == 9) { $pos = 5; $outStr .= " ".$cur; }
			else { $outStr .= $cur; }
			
		} else {
			if($pos == 3) { $lstName = substr $in, $nonEmp, $i-$nonEmp; $pos = 9; }
		}
		
	}
	#die $outStr;
	return $outStr;
	#-----
}
sub prepareXML
{
	my $self = shift;
	my $in = $_[0];
	$in =~ s/[\s]+>/>/g;
	$in =~ s/[\s]+\/>/\/>/g;
	$in =~ s/<[\s]+/</g;
	$in =~ s/<([\w\d:-]+)([^>]*)\/>/<$1$2><\/$1>/g;
	return $in;
}

sub removeComments
{
	my $self = shift;
	my $in = shift;
	#$in = "<wer></eW><!--\n<role r=\"er\">-->e";
	my $p1 = index($in, "<!--");
	my $p2 = index($in, "-->");
	while($p2>$p1) {
		$in = substr($in, 0, $p1).substr($in, $p2+3, length($in) - $p2-3);
		$p1 = index($in, "<!--");
		$p2 = index($in, "-->");		
	}
	return $in;
}
sub unPrepareXML
{
	my $self = shift;
	my $in = $_[0];
	while((my $str = $self->checkForUnPrepare($in)) ne "") {
		$in =~ s|<$str([^>]*)></$str>|<$str$1/>|mig;
	}
	return $in;
}
sub checkForUnPrepare
{
	my ($self, $in) = @_;
	#if("<org></org>" =~ /<([^ ]+)([^>]*)><\/([^>]+)>/) {die $1."=".$2."=".$3;}
	if($in =~ /<([^ >]+)([^>]*)><\/([^>]+)>/) {
		if($1 eq $3) { return $1; }
	}
	return "";
}
sub isStringContent
{
	my $self = shift;
	my $in = $_[0];
	if($in =~ /^[\s]*<([\d\w]+)([^>]*)>/) { return 0; }
	else { return 1; }
} 


# ---------------- from MyCommon
sub removeWS
{
        my $in = $_[0];
        $in =~ s/^[\s]+//g;
        $in =~ s/[\s]+$//g;
        return $in;
}




1;                                                                                                                                                                                                                                                                                                                                                                                             