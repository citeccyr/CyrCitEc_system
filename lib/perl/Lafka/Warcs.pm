package Lafka::Warcs;

## an oo library to manage several warcs

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Find;
use List::Util qw(shuffle);

use Cidig::Conf;
use Lafka::Common;
use Warc::File;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $m={};
  bless $m, $class;
  my $params=shift;
  $m->{'verbose'}=&Lafka::Common::is_a_tty();
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $m->{$key}=$params->{$key};
  }
  return $m;
}

## import a warc file
sub import_warc {
  my $m=shift;
  ## full file
  my $fufi=shift // confess "I don't see your file to import.";
  if(not -f $fufi) {
    confess "I don't see your file $fufi.";
  }
  if($m->{$fufi}) {
    return $m->{$fufi};
  }
  $m->{$fufi}=Warc::File->new({'file'=> $fufi});
  return $m->{$fufi};
}

## removes a warc from memory
sub remove_warc {
  my $m=shift;
  my $fufi=shift // confess "I need a file here.";
  if(not $m->{$fufi}) {
    warn "You asked me to remove $fufi, but I don't have it.";
    return 0;
  }
  delete $m->{$fufi};
}

# ## obsoleted with repetiton problem of 2018-10
# ## check if we have something new in the first vs the second
# sub HAS_FIRST_SOMETHING_NEW_OLD {
#   my $m=shift;
#   my $w1_fufi=shift;
#   my $w2_fufi=shift;
#   my $w1=$m->import_warc($w1_fufi);
#   my $w2=$m->import_warc($w2_fufi);
#   my $pd1=$w1->get_payload_digest();
#   my $pd2=$w2->get_payload_digest();
#   foreach my $pd (keys %$pd1) {
#     if(not $pd2->{$pd1->{$pd}}) {
#       if($m->{'verbose'}) {
# 	print "I found a new payload.\n";
#       }
#       return 1;
#     }
#   }
#   if($m->{'verbose'}) {
#     print "I don't see a new payload.\n";
#   }
#   return 0;
# }

## check if we have something new in the first vs the second
sub has_first_something_new {
  my $m=shift;
  my $w1_fufi=shift;
  my $w2_fufi=shift;
  my $w1=$m->import_warc($w1_fufi);
  my $w2=$m->import_warc($w2_fufi);
  my $d1=$w1->get_digests();
  my $d2=$w2->get_digests();
  my $old_digests={};
  ## put all the old digests in a hash
  my @types=('block','payload');
  foreach my $type (@types) {
    foreach my $d (keys %{$d2->{$type}}) {
      $old_digests->{$d}=1;
    }
  }
  ## if any digest of the second is found in the first, we return false
  foreach my $type (@types) {
    foreach my $d (keys %{$d1->{$type}}) {
      if($old_digests->{$d}) {
	if($m->{'verbose'}) {
	  print "I see a first old payload $d, nothing new.\n";
	}
	return 0;
      }
    }
  }
  if($m->{'verbose'}) {
    print "I pass the payload check for something new.\n";
  }
  return 1;
}

## appends first to seond
sub append_first_to_second {
  my $m=shift;
  my $w1_fufi=shift;
  my $w2_fufi=shift;
  if(not -f $w1_fufi) {
    confess "I can't see the file $w1_fufi";
  }
  if(not -f $w2_fufi) {
    confess "I can't see the file $w2_fufi";
  }
  my $w1=$m->import_warc($w1_fufi);
  my $w2=$m->import_warc($w2_fufi);
  my $fh1=$w1->open_read_file();
  my $fh2=$w2->open_append_file();
  my $line;
  while($line=<$fh1>) {
    print $fh2 $line;
  }
  $fh1->close();
  $fh2->close();
  ## just remove both from the object memory since we should be done here
  $m->remove_warc($w1_fufi);
  $m->remove_warc($w2_fufi);
}

## loads the names of the existing warc files
## fixme:: replace with Cidig::Files::load_from_directory
sub load_warc_files {
  my $m=shift;
  $m->{'conf'}=Cidig::Conf->get({'conf'=>'lafka'});
  my $warc_dir=$m->{'conf'}->{'warc_dir'} // confess "I need this defined.";
  if(not -d $warc_dir) {
    confess "I don't see you warc_dir $warc_dir.";
  }
  my $count_warc=0;
  my $find_warcs = sub {
    my $name=$File::Find::name;
    if(not -f $name or not $name=~m/\.warc$/) {
      return 0;
    }
    $m->{'warcs'}->[$count_warc++]=$name;
  };
  ## this populates m->{'warcs'}
  &find($find_warcs, $warc_dir);
  ## shuffle the warcs
  @{$m->{'warcs'}}=shuffle(@{$m->{'warcs'}});
  return $m->{'warcs'};
}

1;
