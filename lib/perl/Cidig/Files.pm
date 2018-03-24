package Cidig::Files;

## common modules to deal with files
## some of them shamelessly copied from ernad

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Find;
use File::Slurp;
use File::Basename;
use File::Path;
use File::stat;
use List::Util qw(shuffle);
use JSON::XS;

## globals needed for finding most recent files
my $last_time=0;
my $last_file='';

sub load_from_directory {
  my $dir=shift // confess 'I need a directory here.';
  #my $max=shift // 0;
  ## a slash to the directory, otherwise it may not
  ## find anything
  if(not substr($dir,length($dir)-1) eq '/') {
    $dir="$dir/";
  }
  my $regex=shift // '';
  if(not -d $dir) {
    confess "I don't see your directory $dir.";
  }
  my $out;
  my $count_files=0;
  my $find_files = sub {
    my $name=$File::Find::name;
    ## only find regular files, and symlinks to them
    if(not -f $name) {
      return 0;
    }
    if($regex and not $name=~m/$regex/) {
      return 0;
    }
    #if($max>0 and $count_files > $max) {
    #  last;
    #}
    ###
    #print "$name\n";
    ###
    $out->[$count_files++]=$name;
  };
  ## this populates $out
  if(not -d $dir) {
    confess "I don't have the directory $dir.";
  }
  &find($find_files, $dir);
  ## shuffling the files
  @{$out}=shuffle(@{$out});
  return $out;
}

## loads a file list from the cache
sub load_from_cache {
  my $cache_dir=shift // confess "I need a directory here";
  my $type=shift // confess "I need a type here";
  my $fufi="$cache_dir/$type.json";
  if(not -f $fufi) {
    confess "I can't open $fufi";
  }
  my $out=&load_json($fufi);
  return $out;
}

## finds the peren type from a peren file
sub type_from_name {
  my $file=shift;
  my $bana=basename($file);
  my $type=$bana;
  $type=~s|^\d+\.|| or
    confess "This does not look like a peren file.";
  ## deal with compression
  $type=~s|\.gz||;
  return $type;
}

##
sub build_cache_from_directory {
  my $dir=shift // confess 'I need a directory here.';
  my $cache_dir=shift // confess 'I need a cache directory here.';
  my $out={};
  my $count={};
  my $find_files = sub {
    my $name=$File::Find::name;
    ## only find regular files, and symlinks to them
    if(not -f $name) {
      return 0;
    }
    if(not -f $name) {
      return 0;
    }
    my $type=&type_from_name($name) // confess "I need to find the type here";
    $out->{$type}->[$count->{$type}++]=$name;
  };
  ## this populates $out
  &find($find_files, $dir);
  foreach my $type (keys %$out) {
    my $file="$cache_dir/$type.json";
    &dump_json($out->{$type},$file);
  }
}

## loads json
sub load_json {
  my $file=shift;
  #print "I read $file\n";
  my $json=&File::Slurp::read_file($file);
  #my $json=&File::Slurper::read_text($file);
  my $data=decode_json($json);
  return $data;
}

## from ernad code
sub does_file_need_renewal {
  my $file=shift;
  my @others=@_;
  my $verbose=0;
  if(not -f $file) {
    if($verbose) {
      print "file $file is not there, it needs renewing\n.";
    }
    return 1;
  }
  if($verbose) {
    print "file $file is there ... ";
  }
  if(-z $file) {
    if($verbose) {
      print "file $file is empty, it needs renewing\n.";
    }
    return 1;
  }
  ## -M  Script start time minus file modification time, in days.
  my $target_time=-M $file;
  if($verbose) {
    print "target_time is $target_time\n";
  }
  if($verbose) {
    print Dumper @others;
  }
  foreach my $other_file (@others) {
    if($verbose) {
      print "considering $file as renewal target\n";
    }
    if(not $other_file) {
      confess "I don't have the file $other_file";
    }
    if(-d $other_file) {
      ## directory case, not treated recursively
      my $dirname=$other_file;
      opendir( my $dir, $dirname ) or die "Error: can't open dir $dirname";
      my $file;
      while ($file = readdir $dir ) {
        ## skipping "." and ".."
        if ( ($file eq "." ) or ( $file eq ".." )) {
          next;
        }
        $file="$dirname/$file";
        if(-M $file < $target_time) {
          if($verbose) {
            print " $file is newer, renewal required\n";
          }
          return 1;
        }
      }
    }
    ## finished with this
    #next;
    if(not -f $other_file) {
      die "I can not find the file '$other_file'";
    }
    if($verbose) {
      print "time on file $file is ", -M $other_file, "\n";
    }
    if(-M $other_file < $target_time) {
      if($verbose) {
	print " but $other_file is newer, renewal required\n";
      }
      return 1;
    }
  }
  if($verbose) {
    print " no reed to renew\n";
  }
}
## dumps json
sub dump_json {
  my $data=shift;
  my $file=shift;
  my $json=encode_json($data);
  # &File::Slurper::write_text($file,$json);
  &File::Slurp::write_file($file,$json);
  return 1;
}

sub prepare {
  my $fina=shift;
  my $dirname=dirname($fina);
  if(not -d $dirname) {
    mkpath($dirname);
  }
}


sub mtime {
  my $file=shift;
  if(not -f $file) {
    confess "I don't see a file $file";
  }
  my $sb = stat($file);
  my $mtime=$sb->mtime;
  return $mtime;
}

#
# finds the most recent tme in the directory
#
sub find_most_recent_time_in_directory {
  my $directory=shift;
  foreach my $file (`ls $directory`) {
    chomp $file;
    my $full_file="$directory/$file";
    if(-f $full_file) {
      my $mtime=&mtime($full_file);
      if($last_time < $mtime) {
        $last_time=$mtime;
        next;
      }
    }
    if(-d $full_file) {
      &find_most_recent_time_in_directory($full_file);
    }
  }
  return $last_time;
}

##
sub find_most_recent_file_in_directory {
  my $directory=shift;
  foreach my $file (`ls $directory`) {
    chomp $file;
    my $full_file="$directory/$file";
    if(-f $full_file) {
      if(not $last_file) {
	$last_file=$full_file;
      }
      my $mtime=&mtime($full_file);
      if($last_time < $mtime) {
        $last_time=$mtime;
	$last_file=$full_file;
        next;
      }
    }
    if(-d $full_file) {
      &find_most_recent_time_in_directory($full_file);
    }
  }
  return $last_file;
}

1;
