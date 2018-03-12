package Lafka::Input;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Date::Parse;
use String::ShellQuote;
use File::Copy;
use URI::URL;

use Cidig::Conf;
use Cidig::Ris;
use Lafka::Common;
use Lafka::Exclude;
use Lafka::Paths;
use Lafka::Warcs;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $i={};
  bless $i, $class;
  ## get other Lafka variables
  $i->{'file'}=$Lafka::Paths::file;
  $i->{'dir'}=$Lafka::Paths::dir;
  ## copy parameters into the structure
  my $params=shift;
  foreach my $key (keys %{$params}) {
    $i->{$key}=$params->{$key};
  }
  my $ris=$i->{'ris'} // confess "I need a ris here.";
  $i->{'conf'}=Cidig::Conf->get({'conf'=>$ris.'.lafka'});
  ## open the warc manage
  $i->{'m'}=Lafka::Warcs->new();
  #my $ris=$i->{'conf'}->{'ris'} // '';
  #if(not $ris) {
  #  confess "Put your ris= into your configuration file ".$i->{'file'}->{'conf'};
  #}
  ## just a shorthand
  $i->{'id2file'}=$Cidig::Ris::id2file->{$ris}
    // confess "I don't see your id to file function.";
  $i->{'wget_args'}='-O /dev/null --no-warc-compression --no-warc-keep-log --tries=1';
  ## set verbose if we ran on tty
  $i->{'verbose'}=&Lafka::Common::is_a_tty();
  ## a state to see the previous host
  $i->{'previous_hostname'}='';
  $i->{'exclude'}=Lafka::Exclude->new();
  ## get the fullfiller from the configuration.
  my $fullfiller_string=$i->{'conf'}->{'fullfillers'} // confess "I need this defined here.";
  ## the fullfillers are a string, they need to made a reference fullfillers;
  $i->{'fullfillers'}=[];
  my $count_fullfillers=0;
  foreach my $type (split(/,/,$fullfiller_string)) {
    $i->{'fullfillers'}->[$count_fullfillers++]=$type;
  }
  return $i;
}

sub get {
  my $i=shift;
  my $pid=shift // confess "I need an id here.";
  my $futlis=shift // confess "I need a futli arrayref here.";
  my $count_got=0;
  foreach my $futli (@$futlis) {
    my $got=$i->get_by_futli($pid,$futli);
    if($i->{'skip_existing'} and $got == -1) {
      ## no more futli for an existing file
      last;
    }
    $count_got++;
  }
  return $count_got;
}

sub get_by_futli {
  my $i=shift;
  my $pid=shift // confess "I need an id here.";
  $i->{'pid'}=$pid;
  my $futli=shift // confess "I need a futli here.";
  $i->{'futli'}=$futli;
  my $id2file=$i->{'id2file'};
  my $target_file=$i->{'dir'}->{'warc'}.'/'.&{$id2file}($pid).'.warc';
  $i->{'target_file'}=$target_file;
  if($i->{'verbose'}) {
    print "My target_file is $target_file\n";
  }
  if(-f $target_file and $i->{'skip_existing'}) {
    print "I skip the existing $target_file\n";
    return -1;
  }
  my $u=URI::URL->new($i->{'futli'});
  $i->{'hostname'}=$u->authority;
  ## pre-download checks
  $i->should_i_download() or return 0;
  ## this must be set after the pre-download checks
  $i->{'previous_hostname'}=$i->{'hostname'};
  my $warc_dir=$i->{'dir'}->{'warc'};
  my $tmp_file=$i->{'file'}->{'temp_warc'};
  ## for the moment, no check ...
  my $wget_shell=$Lafka::Paths::bins->{'wget'}.' '.$i->{'wget_args'};
  $wget_shell .= " --warc-file " . $i->{'file'}->{'temp_wget'};
  $wget_shell .= " --warc-header \"Paper-Id: $pid\"";
  $wget_shell .= " --warc-header \"Futli: $futli\"";
  ## if this is a html-based (secondary) download
  if($i->{'html'}) {
    my $date=$i->{'html'}->{'date'} // confess "I need a html date.";
    if(not str2time($date)) {
      confess "I don't like your date '$date'";
    }
    my $url=$i->{'html'}->{'url'} // confess "I need a html URL.";
    $wget_shell .= " --warc-header \"HTML-Url: $url\"";
    $wget_shell .= " --warc-header \"HTML-Date: $date\"";
  }
  $wget_shell .= ' ' . shell_quote($futli);
  ## set up required directories
  &Lafka::Common::prep4file($target_file);
  unlink $i->{'file'}->{'temp_warc'};
  system($wget_shell);
  ## wait after the shell run
  if($i->{'wait'}) {
    my $wait=$i->{'wait'};
    #if($i->{'verbose'}) {
      print "I wait $wait\n";
    #}
    sleep $wait;
  }
  if(not -f $i->{'file'}->{'temp_warc'}) {
    warn "I got no warc for $futli\n";
    return;
  }
  if(not -f $target_file) {
    copy($tmp_file,$target_file);
    return 1;
  }
  if($i->{'m'}->has_first_something_new($tmp_file,$target_file)) {
    if($i->{'verbose'}) {
      print "$tmp_file has something new for $target_file.\n";
    }
    $i->{'m'}->append_first_to_second($tmp_file,$target_file);
    return 1;
  }
  elsif($i->{'verbose'}) {
    print "I don't find anything new in $tmp_file for $target_file.\n";
  }
  return 0;
}

sub should_i_download {
  my $i=shift;
  my $target_file=$i->{'target_file'};
  ## target_file too young?
  my $warc_age=-M $target_file // 0;
  my $too_young=$i->{'conf'}->{'warc_too_young_in_days'}
    // confess "I need this defined here.";
  if(-f $target_file and $warc_age < $too_young) {
    if($i->{'verbose'}) {
      print "I skip $target_file, of age $warc_age\n";
    }
    return 0;
  }
  ## check if the pid is excluded. The name of the exclusion
  ## file is in the Lafka configuration.
  if($i->{'exclude'}->is_excluded_by_id($i->{'pid'})) {
    return 0;
  }
  ## check if we have fullfilled
  if(-f $target_file) {
    #print "checking $target_file\n";
    my $w=Warc::File->new({'file'=>$target_file});
    #print Dumper $w;
    ## find any Futli that does not have a payload of any of the payload_types
    my $missing=$w->missing_of_origin('Futli',$i->{'fullfillers'});
    if(not $missing) {
      if($i->{'verbose'}) {
	print "all futlis found\n";
      }
      return 0;
    }
  }
  ## get the hostname from the target URL?
  my $hostname=$i->{'hostname'} ;
  ## // confess "I don't see the hostname";
  ## wait because we have done this hostname just now?
  if(not defined($hostname) or ($hostname  eq $i->{'previous_hostname'})) {
    my $to_sleep=$i->{'conf'}->{'sleep_between_downloads_from_the_same_server'};
    if(not $to_sleep) {
      confess "I am not configured to wait, thus I refuse to download again from $hostname.";
    }
    sleep $to_sleep;
  }
  return 1;
}


1;
