# standart functions for all stripts					    #
#									    #
#  			Package made by prl@mail.ru			    #
#					2004				    #

package MyCommon;

##############################################################################
# Define required packages
##############################################################################

use Data::Dumper;
use strict;
use Exporter;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
use File::stat;
use Time::localtime;


##############################################################################
# Define some constants
##############################################################################
use vars qw(@ISA $VERSION @EXPORT); 


our @ISA 		= qw(Exporter);
our @EXPORT 	= qw(
			GetFileContentArray GetFileContent SaveFileContent GetMDate
			nbsps removeWS 
			WU UW UK KU KW WK
			winlc
			in_array in_array_lc
			urldecode urlencode
			tagValue Global trim
			gohttps dbg
		);
$VERSION 	= "1.0";


##############################################################################
# BODIES
##############################################################################

# win <-> utf
sub WU { return to_utf8({ -string => $_[0], -charset => 'cp1251'}); }
sub KU { return to_utf8({ -string => $_[0], -charset => 'koi8-r'}); }
sub UW { return from_utf8({ -string => $_[0], -charset => 'cp1251'}); }
sub UK { return from_utf8({ -string => $_[0], -charset => 'koi8-r'}); }
sub winlc { my $str = $_[0]; $str =~ s/À-ß/à-ÿ/mgi; return $str; };
sub trim { my $d = $_[0]; $d =~ s/^\s+//; $d =~ s/\s+$//; return $d; }

#sub new { }

# Get string content from file
sub GetFileContent
# file , WU
{
	if(!-e $_[0]) { die "Could not find file ".$_[0]." in ".caller(); }
        if($_[1] && length($_[1]) > 2) { open F, '<:encoding('.$_[1].')', $_[0]; }
        else { open F, $_[0]; }
        #print STDERR 'XX--'.$_[1];
        my $str = doEncode(join("", <F>), $_[1]);
        close F;
        #if($_[0] =~ /ppa6/) { dbg($str, 1); }
        #changeHeader($_[2]);
        return $str;
}

sub SaveFileContent
# file , content, WU
{
   if($_[0] ne "") {
     #if(-e $_[0] && -w $_[0]) {
        open SFCF, ">".$_[0];
        my $str = doEncode($_[1], $_[2]);#dbg($str);
        print SFCF $str;
        close SFCF;
      #} else { die "File ".$_[0]." does not exists or not writable."; }
   }
}

sub GetFileHash
# file //, WU
{
	my $str;
	 my %hs;
	if(!-e $_[0]) { die "Could not find file ".$_[0]." in ".caller(); }
  open F, $_[0];
  my @arr = <F>;
  close F;
  for(my $i = 0; $i < @arr; $i++) {
  	if($arr[$i] =~ /^([^=]+)=([^\n]+)/) { $hs{$1} = $2; }
  }
  return \%hs;
}
sub SaveFileHash
# file , hash  //??, WU
{
	 my %hs = %{$_[1]};
   if($_[0] && scalar keys %hs) {
 			my $str = '';
      open SFCF, ">".$_[0];
      foreach my $key (keys %hs) {
      	$str .= "\n" if $str;
      	$str .= $key.'='.$hs{$key};
      }
      #my $str = doEncode($_[1], $_[2]);#dbg($str);
      print SFCF $str;
      close SFCF;
   }
}
sub AddToFile
{
   if(-e $_[0] && $_[0] ne "" && $_[0] ne "." && $_[0] ne "..") {
        open F, ">>".$_[0];
        my $str = doEncode($_[1], $_[2]);
        print F $str;
        close F;
    }	
}
sub ClearFile
{
    if(-e $_[0] && $_[0] ne "" && $_[0] ne "." && $_[0] ne "..") {
        open F, ">".$_[0];
        close F;	
    }
}
sub changeHeader
{
	my $page = $_[0];
	my $enc = $_[1];
	if($enc eq "W") { $enc = "windows-1251"; }
	elsif($enc eq "W") { $enc = "uft-8"; }
	else { $enc = ""; }
	#if($page =~ /(<head>([]+)<meta http-equiv="Content-Type" content="text/html; charset=windows-1251"><\/head)/)
	
}
sub doEncode
{
	my ($str, $enc) = @_;
	if($enc eq "UW") { return UW($str); }
	elsif($enc eq "WU") { return WU($str); }
	else { return $str; }
}

sub GetFileContentArray
{
	if(!-e $_[0]) { die "Could not find file ".$_[0]." in ".caller(); }
        open F, $_[0];
        my @str = <F>;
        close F;
        return @str;
}
sub removeWS
{
	my $in = $_[0];
	$in =~ s/^[\s]+//g;
	$in =~ s/[\s]+$//g;
	return $in;
}

sub nbsps
{
	my $out = "";
	for(my $i = 0; $i < $_[0]; $i++) { $out .= " "; }
	return $out;
}

sub in_array
{
    my $var = $_[0];
    if($var eq "") { return 0; }
    for(my $i = 1; $i < @_; $i++) { 
        if($var eq $_[$i]) { return $i; }
    }
    return 0;
}
sub in_array_lc
{
    my $var = $_[0];
    if($var eq "") { return 0; }
    for(my $i = 1; $i < @_; $i++) { 
        if(lc($var) eq lc($_[$i])) { return $i; }
    }
    return 0;
}

#sub r in auth.cgi.
sub tagValue
{
   my $in = @_[0];
   $in =~ s/&/&amp;/gi;
   $in =~ s/"/&quot;/gi;	#"
   #!$in =~ s/'/&#39;/gi; #&apos;/gi;
   $in =~ s/</&lt;/gi;
   $in =~ s/>/&gt;/gi;
   return $in;
}
sub urldecode{    
   my ($val)=@_;  
   $val=~s/\+/ /g; $val=~s/%([0-9a-hA-H]{2})/pack('C',hex($1))/ge; 
   return $val; 
}

sub urlencode{
    ($_)=@_;
    s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    $_;
}
				


sub toXml
{
    my $out = $_[0];
    $out =~ s/&/&amp;/mg;
    $out =~ s/"/&quot;/mg;
    $out =~ s/>/&gt;/mg;
    $out =~ s/</&lt;/mg;
    #$out =~ s/"//mg;
    return $out;
}

sub Global
{
	my $in = $_[0];
	if($in eq "oadir") { return $main::oadir; }
	elsif($in eq "ServerName") { return $main::ServerName; }
	elsif($in eq "mod_userhomedir") { return $main::mod_userhomedir; }
	elsif($in eq "mod_usersubdir") { return $main::mod_usersubdir; }
	elsif($in eq "oamail_eng") { return $main::oamail_eng; }
	elsif($in eq "oamail_rus") { return $main::oamail_rus; }
	elsif($in eq "security_dir") { return $main::security_dir; }
	elsif($in eq "users_documents_dir") { return $main::users_documents_dir; }
	elsif($in eq "archives_users_docs") { return $main::archives_users_docs; }
	elsif($in eq "invisible_dir") { return $main::invisible_dir; }
	elsif($in eq "authTimeout") { return $main::authTimeout; }
	elsif($in eq "ServerName") { return $main::ServerName; }
	elsif($in eq "templates_dir") { return $main::templates_dir; }
	elsif($in eq "socionet_host") { return $main::socionet_host; }
	elsif($in eq "sinin_host") { return $main::sinin_host; }
	elsif($in eq "XMLDir") { return $main::XMLDir; }
	elsif($in eq "user_base_tag") { return $main::user_base_tag; }
	else { my $r = ""; eval "\$r = \$main::$in;"; return $r; }
	
	return "";
}
#global $MODULE_MyCommon = 1;

#print "======================\n\n";

sub gohttps
{
    if($ENV{'SCRIPT_URI'} =~ /^http:\/\//) { 
	my $url = $ENV{'SCRIPT_URI'};
	#$url =~ s/^http:/https:/;
	$url = "https://".$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'};
	print "Location: $url\n\n";
	exit;
    }
}


sub getNavigation()
{
#  use POSIX;
  my($total, $onpage, $page, $link) = (@_[0], @_[1], @_[2], @_[3]);
  my $i; my $out;
  if($total > $onpage)
  {
     for($i = 1; $i < 1+POSIX::ceil($total/$onpage); $i++)
     {
      if($page != $i) { $out .= "<a href='$link"."page=$i'>$i</a> "; }
      else { $out .= " $i "; }
    }
    return $out;
  }
  else { return ""; }
}

sub GetMDate
{
    if(-e $_[0]) {
    my $tm = localtime(stat($_[0])->mtime);
    my $t4 = $tm->[4]+1; my $t3 = $tm->[3];
    if($t4 < 10) { $t4 = "0".$t4; }
    if($t3 < 10) { $t3 = "0".$t3; }
    return ($tm->[5] + 1900)."-".$t4."-".$t3;
    }
    return '';
}

sub KW {
    my $str = shift;
    $str =~ tr[\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xB3\xA3][\xC0-\xFF\xA8\xB8];
    $str =~ tr[\x{0410}-\x{044F}\x{0451}\x{0401}][\x{044E}\x{0430}\x{0431}\x{0446}\x{0434}\x{0435}\x{0444}\x{0433}\x{0445}\x{0438}\x{0439}\x{043A}\x{043B}\x{043C}\x{043D}\x{043E}\x{043F}\x{044F}\x{0440}\x{0441}\x{0442}\x{0443}\x{0436}\x{0432}\x{044C}\x{044B}\x{0437}\x{0448}\x{044D}\x{0449}\x{0447}\x{044A}\x{042E}\x{0410}\x{0411}\x{0426}\x{0414}\x{0415}\x{0424}\x{0413}\x{0425}\x{0418}\x{0419}\x{041A}\x{041B}\x{041C}\x{041D}\x{041E}\x{041F}\x{042F}\x{0420}\x{0421}\x{0422}\x{0423}\x{0416}\x{0412}\x{042C}\x{042B}\x{0417}\x{0428}\x{042D}\x{0429}\x{0427}\x{042A}\x{2566}\x{2557}];
    return $str;
}

sub WK {
    my $str = shift;
    $str =~ tr[\xC0-\xFF\xA8\xB8][\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xB3\xA3];
    $str =~ tr[\x{044E}\x{0430}\x{0431}\x{0446}\x{0434}\x{0435}\x{0444}\x{0433}\x{0445}\x{0438}\x{0439}\x{043A}\x{043B}\x{043C}\x{043D}\x{043E}\x{043F}\x{044F}\x{0440}\x{0441}\x{0442}\x{0443}\x{0436}\x{0432}\x{044C}\x{044B}\x{0437}\x{0448}\x{044D}\x{0449}\x{0447}\x{044A}\x{042E}\x{0410}\x{0411}\x{0426}\x{0414}\x{0415}\x{0424}\x{0413}\x{0425}\x{0418}\x{0419}\x{041A}\x{041B}\x{041C}\x{041D}\x{041E}\x{041F}\x{042F}\x{0420}\x{0421}\x{0422}\x{0423}\x{0416}\x{0412}\x{042C}\x{042B}\x{0417}\x{0428}\x{042D}\x{0429}\x{0427}\x{042A}\x{2566}\x{2557}][\x{0410}-\x{044F}\x{0451}\x{0401}];
    return $str;
}

sub me { return $ENV{'REMOTE_ADDR'} eq '85.118.225.254'; }
sub dbg
{
    print ref($_[0]) ? "\n\n".Dumper($_[0]) : "\n\n".$_[0] if $ENV{'REMOTE_ADDR'} eq '85.118.225.254';
    exit if $_[1] && $ENV{'REMOTE_ADDR'} eq '85.118.225.254';
}

1;
