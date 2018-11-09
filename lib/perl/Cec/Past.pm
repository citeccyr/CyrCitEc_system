package Cec::Past;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Encode;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Path;
use File::Temp;
use Text::Diff;
use XML::LibXML;

use Cec::Dates;
use Cec::Paths;
use Cec::Xslt;

my $dirs=$Cec::Paths::dirs;
my $backup_dir=$dirs->{'hist'} // die;
my $www_dir=$dirs->{'www'};
my $l_www_dir=length($www_dir);
my $l_bak_dir=length($backup_dir)+12;
my $l_bas_dir=length($backup_dir);
my @to_backup=('stats.html','stats/');

my @back_dates=@{&Cec::Past::list_dates};

sub list_dates {
  my $o=[];
  my $count=0;
  foreach my $dir (reverse glob("$backup_dir/*")) {
    my $date=basename($dir);
    if(not &Cec::Dates::is($date)) {
      next;
    }
    $o->[$count++]=$date;
  }
  return $o;
}

sub get_prevpath {
  my $current=shift;
  my $base=substr($current,$l_www_dir);
  foreach my $back_date (@back_dates) {
    my $back_file="$backup_dir/$back_date$base";
    if(-f $back_file) {
      if((compare($current,$back_file) == 0)) {
	#print "I see a change in  $old_file vs $current_file.\n";
	next;
      }
      my $back_path=substr($back_file,($l_bas_dir+1));
      return $back_path;
    }
  }
  return '';
}

sub clean {
  my $date=shift // &Cec::Dates::yesterday();
  my $to_clean_dir="$backup_dir/$date";
  if(not -d $to_clean_dir) {
    print "I don't see $to_clean_dir to clean.";
    return;
  }
  foreach my $old_file (`find $to_clean_dir -type f`) {
    chomp $old_file;
    if(-l $old_file) {
      next;
    }
    my $base=substr($old_file,$l_bak_dir);
    my $current_file="$www_dir/$base";
    if(not (compare($old_file,$current_file) == 0)) {
      #print "I see a change in  $old_file vs $current_file.\n";
      next;
    }
    move($old_file, "$old_file.gone");
    my $s="ln -sr $current_file $old_file";
    #print "$s\n";
    system($s);
  }
}

## clear up the .gone files
sub purge {
  my $date=shift // &Cec::Dates::ago_2();
  my $to_purge_dir="$backup_dir/$date";
  system(`find $to_purge_dir -name '*.gone' -delete`);
}

sub make_index {
  my $doc=XML::LibXML::Document->new('1.0','utf-8');
  my $dates_ele=$doc->createElement('dates');
  $dates_ele->appendText("\n ");
  foreach my $file (reverse glob("$backup_dir/*")) {
    if(not -d $file) {
      next;
    }
    my $bana=basename($file);
    if(not $bana=~m|^\d{4}-\d{2}-\d{2}$|) {
      next;
    }
    #if($bana eq $today) {
    #  next;
    #}
    my $date_ele=$doc->createElement('date');
    $date_ele->appendText($bana);
    $dates_ele->appendChild($date_ele);
    $dates_ele->appendText("\n ");
  }
  $doc->setDocumentElement($dates_ele);
  my $html=&Cec::Xslt::transform($doc,'index');
  $html->toFile("$www_dir/index.html");
  ## same dot for the past statistics
  $html=&Cec::Xslt::transform($doc,'past_statistics');
  $html->toFile("$www_dir/past_statistics.html");
}

sub backup {
  my $today_dir="$backup_dir/" . &Cec::Dates::today();
  if(not -d $today_dir) {
    mkpath($today_dir);
  }
  my $verbose=0;
  foreach my $target_bana (@to_backup) {
    my $target="$today_dir/$target_bana";
    if($target_bana=~s|/$||) {
      if(not -d $target) {
	mkpath($target);
      }
      ## add the slash back on
      $target_bana.='/';
    }
    my $s="rsync -aq $www_dir/$target_bana $target";
    if($verbose) {
      print "$s\n";
    }
    system($s);
  }
}

1;
