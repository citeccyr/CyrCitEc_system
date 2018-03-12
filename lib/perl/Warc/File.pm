package Warc::File;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Date::Parse;
use IO::File;

use Warc::Constants;
use Warc::Checks;
use Warc::Record;
use Warc::Warcinfo;

## parameters in our warc
## file --> name of file
## fh --> handle for the file to read from
## count_recs --> count of records, starting with 0
## count_current_record --> count of records, starting with 1
## warc_version_is_possible --> start of record possible, Boolean
## warc_type_possible --> start of warc_type possible, Boolean
## count_last_blank_lines --> count the last blank lines
## count_bytes --> count the bytes

## current record, for ease of reference
my $r;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $w={};
  bless $w, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $w->{$key}=$params->{$key};
  }
  $w->file_check();
  ## not parsed yet
  $w->{'is_parsed'}=0;
  return $w;
}

## FixMe: only works here for a single futli
sub report_on_missing {
  my $w=shift;
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  my $origin=shift // confess "I need an origin here, try 'Futli'.";
  ## a store for our informatio
  my $out;
      $out->{'file'}=$w->{'file'};
  ## value of the $origin field, usually the value of the futli
  foreach my $rec (@{$w->{'recs'}}) {
    ## the current value of the origin
    if($rec->{'type'} eq 'warcinfo') {
      $out->{'value'}=$rec->{'warcinfo'}->{'info'}->{$origin} // confess "I need a $origin here.";
      $out->{'papid'}=$rec->{'warcinfo'}->{'info'}->{'Paper-Id'} // confess "I need a Paper-Id here.";
    }
    ## skip if not a response
    if(not $rec->{'response'}) {
      next;
    }
    my $this_type=$rec->{'response'}->{'header'}->{'content-type'};
    $out->{'type'}=$this_type;
  }
  my $type=$out->{'type'} // '';
  if(lc(substr($type,0,9)) ne 'text/html') {
    print Dumper $out;
  }
}


## check we have a file set and it's a file
sub file_check {
  my $w=shift;
  my $file=$w->{'file'};
  if(not $file) {
    confess "I need a file name for my warc.";
  }
  if(not -f $file) {
    confess "I can't see your file '$file'.";
  }
}

sub get_fh {
  my $w=shift;
  if($w->{'fh'}) {
    return $w->{'fh'};
  }
  $w->open_read_file();
  return $w->{'fh'};
}

sub open_read_file {
  my $w=shift;
  if($w->{'fh'}) {
    warn "You are asking me to open a file '".$w->{'file'}."' that is open.";
    return $w->{'fh'};
  }
  $w->file_check();
  $w->{'fh'} = IO::File->new();
  my $file=$w->{'file'};
  my $fh=$w->{'fh'};
  $fh->open("< $file");
  ## no wide character semantics!
  binmode($fh,':raw');
  return $fh;
}

## should only be used by external calls
sub open_append_file {
  my $w=shift;
  if($w->{'fh'}) {
    $w->{'fh'}->close();
  }
  $w->file_check();
  $w->{'fh'} = IO::File->new();
  my $file=$w->{'file'};
  my $fh=$w->{'fh'};
  $fh->open(">> $file");
  ## no wide character semantics!
  binmode($fh,':raw');
  return $fh;
}

sub init {
  my $w=shift;
  ## fixme: do we really need all this variables?
  $w->{'warc_version_is_possible'}=1;
  $w->{'count_bytes'}=0;
  $w->{'count_recs'}=0;
  $w->{'count_lines'}=0;
  $r=Warc::Record->new({'start_byte' => 0});
  undef $w->{'recs'};
  return $w;
}

sub close_read_file {
  my $w=shift;
  if(not $w->{'fh'}) {
    warn "You are asking me to close a file that is not open.";
  }
  $w->{'fh'}->close();
  undef $w->{'fh'};
}

## main record information gathering
sub parse {
  my $w=shift;
  my $fh=$w->open_read_file();
  $w->init();
  my $line;
  $w->{'recs'}->[$w->{'count_recs'}]=$r;
  ## should I jump?
  my $jump=0;
  $line='';
  while(1) {
    if($jump) {
      $fh->seek($jump,1);
    }
    $line=<$fh>;
    if(not $line) {
      last;
    }
    # $w->{'current_line'}=$line;
    # $w->{'count_lines'}++;
    $jump=$r->add_line($line);
    if(not $r->{'closed'}) {
      next;
    }
    ## after closure of a record
    my $end_byte=$r->{'end_byte'} // confess "I need this confined here.";
    $w->{'count_recs'}++;
    $r=Warc::Record->new({'start_byte' => $end_byte});
    $w->{'recs'}->[$w->{'count_recs'}]=$r;
    ## r->add_line did not add the start line of the record, do it here.
    $r->add_line($line);
  }
  ## delete the last record, it will be empty
  delete $w->{'recs'}->[$w->{'count_recs'}];
  ## second, parse the bodies
  foreach my $rec (@{$w->{'recs'}}) {
    $rec->parse_body($fh);
  }
  $w->{'is_parsed'}=1;
  $w->close_read_file();
  $w->clean();
}

## shows a record by number, starting with 1
sub show_record {
  my $w=shift;
  my $number=shift;
  my $rec=$w->{'recs'}->[$number-1];
  if(not $rec) {
    return;
  }
  my $fh=$w->open_read_file();
  my $start_byte=$rec->{'start_byte'} // confess "I need this defined here.";
  my $length=$rec->{'length'} // confess "I need this defined here.";
  my $out;
  $fh->seek($start_byte,0);
  $fh->read($out,$length);
  print $out;
}

## shows a record body by number, starting with 1
sub show_body {
  my $w=shift;
  my $number=shift;
  my $rec=$w->{'recs'}->[$number-1];
  if(not $rec) {
    return;
  }
  my $fh=$w->open_read_file();
  my $start_byte=$rec->{'start_body_byte'} // confess "I need this defined here.";
  my $length=$rec->{'body_length'} // confess "I need this defined here.";
  my $out;
  $fh->seek($start_byte,0);
  $fh->read($out,$length);
  print $out;
}

## find the payload in a hash
sub get_payload_digest {
  my $w=shift;
  my $payload_digest;
  foreach my $rec (@{$w->{'recs'}}) {
    my $digest=$rec->{'warc_header'}->{'WARC-Block-Digest'} // next;
    $payload_digest->{$digest}=1;
  }
  $w->{'$payload_digest'}=$payload_digest;
  return $payload_digest;
}

## remove data that is not required after parsing
## should be in Warc::Record
sub clean {
  my $w=shift;
  my $type=shift // '_';
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  delete $w->{'count_bytes'};
  delete $w->{'count_lines'};
  foreach my $rec (@{$w->{'recs'}}) {
    delete $rec->{'warc_type_is_expected'};
    delete $rec->{'warc_optional_header_is_expected'};
    delete $rec->{'count_previous_bytes'};
    delete $rec->{'count_headers'};
    delete $rec->{'count_bytes'};
    delete $rec->{'warc_version_is_possible'};
    delete $rec->{'count_last_blank_lines'};
    delete $rec->{'closed'};
  }
  return ;
}

## get payloads of a type
sub payloads {
  my $w=shift;
  my $pl_type=shift // '_';
  my $origin=shift // confess "I need an origin here, try 'Futli'.";
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  ## found already ? return it
  if($w->{'payloads'}->{$pl_type}) {
    return $w->{'payloads'}->{$pl_type};
  }
  my $count_pl=0;
  ## an array payloads in warc order
  my $pl=[];
  ## value of the $origin field
  my $value='';
  foreach my $rec (@{$w->{'recs'}}) {
    ## the current value of the origin
    if($rec->{'type'} eq 'warcinfo') {
      $value=$rec->{'warcinfo'}->{'info'}->{$origin} // confess "I need a $origin here.";
    }
    ## skip if not a response
    if(not $rec->{'response'}) {
      next;
    }
    ## check that the payload length is above 0. For some reason that
    ## need fixing, if the length of the payload is zero
    ## $rec->{'payload_length'} appears to be undefined
    if(not defined($rec->{'payload_length'})) {
      ## empty payload
      next;
    }
    my $this_type=$rec->{'response'}->{'header'}->{'content-type'};
    ## if there is no type
    if(not $this_type) {
      ## maybe there was it was a redirect
      if(not $rec->{'response'}->{'header'}->{'content-length'} or
	 $rec->{'response'}->{'header'}->{'location'}) {
	## it was just a redirect
	next;
      }
      ## or it was a 404
      if($rec->{'response'}->{'status'} == 404) {
	## it was not there
	next;
      }
      if($rec->{'response'}->{'status'} == 500) {
	## shit hit the fan
	next;
      }
      else {
	print $w->{'file'},"\n";
	die Dumper $rec->{'response'}->{'header'};
      }
    }
    if($pl_type ne '_') {
      ## we need to reduce this_type to be the same length as $type,
      ## to deal with 'text/html; charset=utf-8'
      $this_type=substr($this_type,0,length($pl_type));
      #print "$this_type $pl_type\n";
      if(lc($this_type) ne lc($pl_type)) {
	next;
      }
    }
    $pl->[$count_pl]->{'start'}=$rec->{'start_payload_byte'};
    $pl->[$count_pl]->{'length'}=$rec->{'payload_length'};
    $pl->[$count_pl]->{'date'}=$rec->{'warc_header'}->{'WARC-Date'};
    $pl->[$count_pl]->{$origin}=$value;
    $pl->[$count_pl]->{'warc'}=$w->{'file'};
    $count_pl++;
  }
  $w->{'payloads'}->{$pl_type}=$pl;
  return $pl;
}


## get resources
sub resources {
  my $w=shift;
  my $re_type=shift // '_';
  my $target_type=shift // confess "I need a target_type here, e.g. 'application/pdf'.";
  my $origin=shift // confess "I need an origin here, try 'Futli'.";
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  ## found already ? return it
  if($w->{'resources'}->{$re_type}) {
    return $w->{'resources'}->{$re_type};
  }
  my $count_re=0;
  ## an array payloads in warc order
  my $re=[];
  ## value of the $origin field
  my $value='';
  foreach my $rec (@{$w->{'recs'}}) {
    ## the current value of the origin
    if($rec->{'type'} eq 'warcinfo') {
      $value=$rec->{'warcinfo'}->{'info'}->{$origin} // confess "I need a $origin here.";
    }
    ## skip if not a response
    if(not $rec->{'resource'}) {
      next;
    }
    my $stream=$rec->{'resource'};
    if(not defined($Warc::Checks::c->{$target_type})) {
      confess "I have no checked defined for your resource type $target_type.";
    }
    if(not &{$Warc::Checks::c->{$target_type}}($stream->{'body'})) {
      next;
    }
    $re->[$count_re]->{'start'}=$rec->{'resource'}->{'start'};
    $re->[$count_re]->{'length'}=$rec->{'resource'}->{'length'};
    $re->[$count_re]->{'date'}=$rec->{'warc_header'}->{'WARC-Date'};
    $re->[$count_re]->{$origin}=$value;
    $re->[$count_re]->{'warc'}=$w->{'file'};
    $count_re++;
  }
  $w->{'resources'}->{$re_type}=$re;
  return $re;
}

## returns array of warcinfos of a certain field name
sub warcinfos {
  my $w=shift;
  my $field_name=shift // confess "I need a field name here.";
  foreach my $rec (@{$w->{'recs'}}) {
    ## is it a warcinfo
    my $wi=$rec->{'warcinfo'} // next;
    my $value=$wi->{'info'}->{$field_name};
    ## seen before?
    if($w->{'warcinfo'}->{$field_name}->{$value}) {
      next;
    }
    ## as a hash
    $w->{'warcinfo'}->{$field_name}->{$value}=1;
    push(@{$w->{'warcinfos'}->{$field_name}},$value);
  }
  return $w->{'warcinfos'}->{$field_name};
}

## returns a hash of values of an orgin missing in payloads of payload_types
sub missing_of_origin {
  my $w=shift;
  ## original field name in warcinfo header
  my $origin=shift // confess "I need a field name here, try 'Futli'";
  ## allowed payload types
  my $payload_types=shift // confess "I need payload_types here.";
  my $payload_types_ref=ref $payload_types;
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  if(not ($payload_types_ref eq 'ARRAY' or $payload_types_ref eq 'HASH')) {
    confess "I need the payload_types as an array ref or a hash ref."
  }
  ## convert hash ref to array
  if($payload_types_ref eq 'HASH') {
    ## maybe this works ....
    @{$payload_types}=keys %{$payload_types};
  }
  my $values=$w->warcinfos($origin);
  my $i_miss={};
  foreach my $value (@$values) {
    $i_miss->{$value}=1;
    #print "I consider $futli\n";
    foreach my $type (@{$payload_types}) {
      my $pls=$w->payloads($type,$origin);
      my $count_pls=0;
      while($pls->[$count_pls]) {
	my $this_value=$pls->[$count_pls]->{$origin} // confess "I need this defined.";
	if($this_value eq $value) {
	  delete $i_miss->{$value};
	}
	else {
	  #print "$this_value $value\n";
	}
	$count_pls++;
      }
    }
  }
  if(not keys %{$i_miss}) {
    return 0;
  }
  foreach my $value (keys %{$i_miss}) {
    $w->{'missing'}->{$origin}->{$value}=1;
  }
  return $w->{'missing'};
}

sub do_i_have {
  my $w=shift;
  my $pl_type=shift // '_';
  my $origin=shift // confess "I need an origin here, try 'Futli'.";
  if(not $w->{'is_parsed'}) {
    $w->parse();
  }
  my $pls=$w->payloads($pl_type,'Futli');
  if(scalar(@$pls)) {
    #print "found payload\n";
    return 1;
  }
  #print "found no payload\n";
  ## approach via resources
  my $res=$w->resources('application/octet-stream',$pl_type,'Futli');
  if(scalar(@$pls)) {
    if($w->{'verbose'}) {
      print "found payload\n";
    }
    return 1;
  }
  if($w->{'verbose'}) {
    print "Found nothing\n";
  }
  return 0;
}

## gets pdfs, first by trying the direct route, then the indirect one
sub get_pdfs {
  my $w=shift;
  undef $w->{'pdfs'};
  my $pdfs;
  $pdfs=$w->payloads('application/pdf','Futli');
  foreach my $pdf (@$pdfs) {
    push(@{$w->{'pdfs'}},$pdf);
  }
  $pdfs=$w->resources('_','application/pdf','Futli');
  foreach my $pdf (@$pdfs) {
    push(@{$w->{'pdfs'}},$pdf);
  }
  return $w->{'pdfs'};
}




1;
