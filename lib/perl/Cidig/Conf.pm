package Cidig::Conf;

## configuration used by cidig.

use strict;
use warnings;

use Carp qw(confess);
#use Clone;
use Config::Tiny;
use Data::Dumper;

## a single method that will do pretty much everything and returns a configuration
sub get {
  my $this=shift;
  my $class=ref($this) || $this;
  my $c={};
  bless $c, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $c->{$key}=$params->{$key};
  }
  ## use $v to be the verbose setting
  my $verbose=$c->{'verbose'};
  our $conf = Config::Tiny->new;

  ## default configuration.
  my $home_dir=$ENV{'HOME'} // confess "I don't see your home directory.";
  my $etc_dir="$home_dir/etc" // confess "I don't see your ~/etc directory.";

  ## this is the default configurtation file.
  ## we may include a command line option to overwrite it. To be done later
  my $file="$etc_dir/cidig.conf";

  if(not -f $file) {
    confess "I can't see your configuration file $file";
  }

  ## this is the main configuration
  our $main = Config::Tiny->read($file,'utf8');
  #print Dumper $main;

  ## if we load with a special conf= parameter, read the
  ## configuration in that file into the main section
  ## and return only the main section
  if($c->{'conf'}) {
    my $conf_param=$c->{'conf'};
    my $conf_file="$etc_dir/$conf_param.conf";
    if(not -f $conf_file) {
      confess "I don't see your conf file $conf_file";
    }
    my $special = Config::Tiny->read($conf_file,'utf8');
    #print Dumper $special;
    foreach my $field (keys %{$special->{'_'}}) {
      $main->{'_'}->{$field}=$special->{'_'}->{$field};
    }
    ## return only the main section
    return $main->{'_'};
  }

  ## load special configurations by section mentioned in the main file
  foreach my $section (keys %$main) {
    if($c->{'conf'} and $c->{'conf'} eq $section) {
      ## that section was already read into the main configuration
      delete $main->{$section};
      next;
    }
    if($verbose) {
      print "I found a section $section\n";
    }
    ## if we have a local configuration file for this section
    my $special_conf_file="$etc_dir/$section.conf";
    if(-f "$special_conf_file") {
      if($verbose) {
	print "I see you have a $special_conf_file\n";
      }
      my $special = Config::Tiny->read($special_conf_file,'utf8');
      ## this can only have a general section
      $special=$special->{'_'};
      foreach my $field (keys %$special) {
	$main->{$section}->{$field}=$special->{$field};
      }
    }
  }
  return $main;
}

1;


