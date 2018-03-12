package Cidig::Paths;

use strict;
use warnings;

use Carp qw(confess);
use Config::Tiny;
use Data::Dumper;

# use Cidig::Conf;
# 
### directories for configuration
#our $dir;
#$dir->{'home'}=$ENV{'HOME'};
#$dir->{'etc'}=$ENV{'HOME'}.'/etc';
#$dir->{'bin'}=$ENV{'HOME'}.'/bin';
#
#our $file;
#
### directories from the configuration
#my $conf = Cidig::Conf->get({'conf'=>'lafka'});
#$dir->{'warc'}=$conf->{'warc_dir'};
#if(not -d $dir->{'warc'}) {
#  confess "I can't see your warc_dir \'".$dir->{'warc'}."\'.";
#}
#$dir->{'summ'}=$conf->{'summ_dir'};
#if(not -d $dir->{'summ'}) {
#  confess "I can't see your summ_dir \'".$dir->{'summ'}."\'.";
#}
#
#$dir->{'temp'}=$conf->{'temp_dir'} // '/tmp';
#if(not -d $dir->{'temp'}) {
#  confess "I can't see your temp_dir \'".$dir->{'temp'}."\'.";
#}
#
### we use the process id for the temporary file. This
### enables us to run serveal process at the same time
#$file->{'temp_wget'}=$dir->{'temp'}.'/'.$$;
#
### wget adds the '.warc' at the end
#$file->{'temp_warc'}=$file->{'temp_wget'}.'.warc';
#
### let's set paths to binaries here. if need be we can
### move to configuration later
our $bin;
$bin->{'wget'}='/usr/bin/wget';
$bin->{'grep'}='/bin/grep';
$bin->{'find'}='/usr/bin/find';
## the one that is traditinonally userd
$bin->{'poppler'}='/usr/bin/pdftotext';
## pdfminer
$bin->{'pdfminer'}='/usr/bin/pdf2txt';
$bin->{'pdf-stream'}='/usr/bin/pdf-stream-cli';


1;


