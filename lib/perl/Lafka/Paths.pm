package Lafka::Paths;

use strict;
use warnings;

use Carp qw(confess);
use Config::Tiny;
use Data::Dumper;

use Cidig::Conf;

## directories for configuration
our $dir;
$dir->{'home'}=$ENV{'HOME'};
$dir->{'etc'}=$dir->{'home'}.'/etc';
$dir->{'bin'}=$dir->{'home'}.'/bin';
$dir->{'lafka'}=$dir->{'home'}.'/lafka';
$dir->{'cache'}=$dir->{'lafka'}.'/opt/input';
$dir->{'input'}=$dir->{'home'}.'/var/opt/input';

our $file;

## directories from the configuration
my $conf = Cidig::Conf->get({'conf'=>'lafka'});
$dir->{'warc'}=$conf->{'warc_dir'};
if(not -d $dir->{'warc'}) {
  confess "I can't see your warc_dir \'".$dir->{'warc'}."\'.";
}

#$dir->{'summ'}=$conf->{'summ_dir'};
#if(not -d $dir->{'summ'}) {
#  confess "I can't see your summ_dir \'".$dir->{'summ'}."\'.";
#}

$dir->{'temp'}=$conf->{'temp_dir'} // '/tmp';
if(not -d $dir->{'temp'}) {
  confess "I can't see your temp_dir \'".$dir->{'temp'}."\'.";
}

## we use the process id for the temporary file. This
## enables us to run serveal process at the same time
$file->{'temp_wget'}=$dir->{'temp'}.'/'.$$;

## wget adds the '.warc' at the end
$file->{'temp_warc'}=$file->{'temp_wget'}.'.warc';

## let's set paths to binaries here. if need be we can
## move to configuration later
our $bins;
$bins->{'wget'}='/usr/bin/wget';
$bins->{'grep'}='/bin/grep';
$bins->{'find'}='/usr/bin/find';

## should really be bin, so I redefine
our $bin=$bins;

1;


