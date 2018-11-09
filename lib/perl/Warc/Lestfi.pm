package Warc::Lestfi;

## get contents form a file in bytes
## the name comes from "FIle STart LEngth". I just reordered the parts.

use strict;
use warnings;

use Carp qw(confess);
use Digest::SHA qw(sha1_base64);
use IO::File;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $f={};
  bless $f, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $f->{$key}=$params->{$key};
  }
  $f->check();
  ## not parsed yet
  return $f;
}

## check whether we have the parameters
sub check {
  my $f=shift;
  ## use warc or file
  my $warc=$f->{'warc'};
  ## if this is not set, allow for f->{'file'}
  if(not $warc) {
    $warc=$f->{'file'};
    $f->{'warc'}=$f->{'file'};
  }
  if(not $warc) {
    confess "I need a file name for my warc.";
  }
  if(not -f $warc) {
    confess "I can't see your file '$warc'.";
  }
  my $start=$f->{'start'} // confess "I need a start here.";
  if(not $start=~m|^\d+$|) {
    confess "I can't deal with your start $start.";
  }
  my $length=$f->{'length'} // confess "I need a length here.";
  if(not $length=~m|^\d+$|) {
    confess "I can't deal with your length $length.";
  }
}

## open the warc
sub open_file {
  my $f=shift;
  $f->{'fh'} = IO::File->new();
  my $file=$f->{'warc'};
  $f->{'fh'}->open("< $file");
  ## no wide character semantics!
  binmode($f->{'fh'},':raw');
  return $f->{'fh'};
}

## loads content into memory
sub load_file {
  my $f=shift;
  my $fh=$f->{'fh'} // $f->open_file();
  $fh->seek($f->{'start'},0);
  my $payload='';
  $fh->read($payload,$f->{'length'});
  $f->{'payload'}=$payload;
  $fh->close();
  delete $f->{'fh'};
  return $payload;
}

## saves to a file
sub save_file {
  my $f=shift;
  ## output file
  my $file=shift;
  ## old_digests
  #my $old_digests=shift // '';
  my $ih=$f->{'fh'} // $f->open_file();
  my $payload=$f->{'payload'} // $f->load_file();
  #my $digest=&sha1_base64($payload);
  #if($old_digests) {
  #  if(ref($old_digests) ne 'HASH') {
  #    confess "I need a hashref of old digests.";
  #  }
  #  foreach my $old_digest (keys %$old_digests) {
  #    if($old_digest eq $digest) {
  #	return '';
  #    }
  #  }
  #}
  my $oh = IO::File->new();
  $oh->open("> $file") or confess "I could not open '$file'";
  ## no wide character semantics!
  binmode($oh,':raw');
  print $oh $payload;
  $oh->close();
  if(-z $file) {
    confess "My file $file is empty.";
  }
  #return $digest;
  return $file;
}


## saves to a file handle
sub save_fh {
  my $f=shift;
  ## output filehandle
  my $oh=shift;
  my $ih=$f->{'fh'} // $f->open_file();
  my $payload=$f->{'payload'} // $f->load_file();
  ## no wide character semantics!
  binmode($oh,':raw');
  print $oh $payload;
  $oh->close();
  return $oh;
}


## saves to a file
#sub save_tmp_file {
#  my $f=shift;
#  ## output file
#  my $file=shift;
#  my $ih=$f->{'fh'} // $f->open_file();
#  my $payload=$f->{'payload'} // $f->load_file();
#  my $oh = File::Temp->new();
#  my $out_file = $fh->filename;
#  ## no wide character semantics!
#  binmode($oh,':raw');
#  print $oh $payload;
#  $oh->close();
#  return $out_file;
#}



1;
