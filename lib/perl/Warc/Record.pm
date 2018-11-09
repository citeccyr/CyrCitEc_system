package Warc::Record;

use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use Date::Parse;
use HTTP::Parser::XS qw(parse_http_request parse_http_response HEADERS_AS_HASHREF);
use HTTP::Response;
use HTTP::Request;
use IO::File;

use Warc::Constants;
use Warc::Warcinfo;

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $r={};
  bless $r, $class;
  my $params=shift;
  ## pass the file parameter with a name file
  ## copy parameters into the structure
  foreach my $key (keys %{$params}) {
    $r->{$key}=$params->{$key};
  }
  ## some initializations
  $r->{'warc_version_is_possible'}=1;
  $r->{'count_last_blank_lines'}=0;
  $r->{'count_headers'}=0;
  $r->{'body'}='';
  if($r->{'start_byte'} > 0) {
    $r->{'count_bytes'}=$r->{'start_byte'};
  }
  return $r;
}

## analyse a line, returns something positive if it can jump
sub add_line {
  my $r=shift;
  my $line=shift // confess "I need a line here.";
  my $count_line=shift;
  if(not $r->{'start_line'}) {
    $r->{'start_line'}=$count_line;
  }
  else {
    $r->{'end_line'}=$count_line;
  }
  ## a blank line
  if($line=~m|^\s*$|) {
    $r->{'count_last_blank_lines'}++;
  }
  else {
    $r->{'count_last_blank_lines'}=0;
  }
  ## if this is not the first line in the file, or the
  ## first in a new record part
  if($r->{'count_bytes'}
     and $r->{'count_bytes'} != $r->{'start_byte'}) {
    $r->{'count_previous_bytes'}=$r->{'count_bytes'};
  }
  else {
    $r->{'count_previous_bytes'}=0;
  }
  ## the line contents. We use this for headers only
  my $contents=$line;
  $contents=~s|\r\n$||;
  ## if there are two blank we may have a new version
  if($r->{'count_previous_bytes'}>2) {
    $r->{'warc_version_is_possible'}=1;
  }
  ## if it is possible a new record is there, lets look
  ## if it thes in one.
  if($r->{'warc_version_is_possible'}) {
    if($r->check_warc_version($contents)) {
      $r->{'count_bytes'}+=length($line);
      return 0;
    }
  }
  ## only add the bytes once we are sure we have not started a new record.
  ## move the current bytes forward
  $r->{'count_bytes'}+=length($line);
  if($r->{'warc_type_is_expected'}) {
    $r->check_warc_type($contents) and return 0;
  }
  if($r->{'warc_optional_header_is_expected'}) {
    ## fixme, this does not take account that lines may overlap onto
    ## continuation lines. Hopefully wget does not use them.
    my $search=$Warc::Constants::header_search // confess "I need this defined here.";
    my $i_have_a_content_length=0;
    # if($contents=~m|^([^:]+):\s+(.*)$|) {
    if($contents=~m|$search|) {
      my $name=$1;
      my $value=$2;
      if(not $Warc::Constants::field->{$name}) {
	confess "I don't know about your warc header $name.\n"
      }
      $r->{'warc_header'}->{$name}=$value;
      ## jump over the contents onces we find the content-length
      if($contents=~m|^Content-Length: (\d+)|) {
	my $body_length=$1;
	$r->{'warc_optional_header_is_expected'}=0;
	$r->{'warc_version_is_possible'}=1;
	## take account of the blank line
	$r->{'start_body_byte'}=$r->{'count_bytes'}+2;
	$r->{'body_length'}=$body_length;
	$r->{'count_bytes'}+=$body_length;
	return $body_length;
      }
    }
  }
  ## this should no longer happen
  if($line=~m|^\s*$| and not $r->{'body'}) {
    $r->{'warc_optional_header_is_expected'}=0;
    return 0;
  }
  return 0;
}

## check the warc-version line. This opens and closes recs
sub check_warc_version {
  my $r=shift;
  my $contents=shift;
  my $warc_version=$Warc::Constants::version // confess "I need this defined.";
  if($contents ne $warc_version) {
    return 0;
  }
  if($r->{'count_previous_bytes'}) {
    ## we can't use "close", it is taken
    $r->close_record();
  }
  $r->{'warc_type_is_expected'}=1;
  return $r;
}

## check the warc-type. This comes after the warc-version line
sub check_warc_type {
  my $r=shift;
  my $contents=shift;
  my $warc_type_search=$Warc::Constants::type_search // confess "I need this defined.";
  if(not $contents=~m|$warc_type_search(.*)|) {
    confess "I can't see your warc type.";
    return 0;
  }
  my $warc_type_found=$1;
  my $warc_record_type=$Warc::Constants::type // confess "I need this defined.";
  if(not $warc_record_type->{$warc_type_found}) {
    confess "Fixme: I don't know about your warc-type '$warc_type_found'.";
  }
  $r->{'type'}=$warc_type_found;
  $r->{'warc_type_is_expected'}=0;
  $r->{'warc_optional_header_is_expected'}=1;
  return 1;
}

## close the record
sub close_record {
  my $r=shift;
  my $count_recs=$r->{'count_recs'};
  ## this is the one we are about to clase
  $r->{'end_byte'}=$r->{'count_bytes'};
  $r->{'body_end_byte'}=$r->{'count_bytes'};
  $r->{'length'}=$r->{'end_byte'} - $r->{'start_byte'};
  $r->{'content_length'}=$r->{'body_end_byte'} - $r->{'start_body_byte'};
  # $r->parse_body();
  $r->{'closed'}=1;
}

## parses a record body, depending on the record type
sub parse_body {
  my $r=shift;
  my $fh=shift;
  my $start=$r->{'start_body_byte'} // confess "I need a start byte.";
  my $length=$r->{'body_length'} // confess "I need a body length.";
  my $body='';
  $fh->seek($start,0);
  $fh->read($body,$length);
  my $type=$r->{'type'};
  if($r->{'type'} eq 'request') {
    $r->{$type}={};
    my $ret = parse_http_request($body,$r->{$type});
    if($ret < 0) {
      ## the function call above has failed, try with http::request
      my $req = HTTP::Request->parse($body);
      foreach my $field_name ($req->header_field_names()) {
	$r->{$type}->{'header'}->{lc($field_name)}=$req->header($field_name) // die;
      }
    }
  }
  elsif($r->{'type'} eq 'resource') {
    $r->{$type}->{'length'}=length($body);
    $r->{$type}->{'start'}=$start;
    $r->{$type}->{'body'}=$body;
  }
  elsif($r->{'type'} eq 'response') {
    my ($ret,$minor_version,$status,$message,$headers)
      = parse_http_response($body,HEADERS_AS_HASHREF);
    if($ret < 0) {
      ## the function call above has failed, try with http::response
      my $res = HTTP::Response->parse($body);
      my $content_length=length($res->content);
      ## remove content from memory
      $res->content('');
      ## try to find the start_payload_byte
      my $headers_as_string=$res->headers_as_string();
      my $headers_length=length($res->headers_as_string());
      foreach my $field_name ($res->header_field_names()) {
	$r->{$type}->{'header'}->{lc($field_name)}=$res->header($field_name) // die;
      }
      ##$r->{$type}->{'status'}=$res->status();
      $r->{$type}->{'message'}=$res->message();
      $r->{'start_payload_byte'}=$r->{'start_body_byte'}+$length-$content_length; ## ouch
      #$r->{'payload_length'}=$r->{'body_length'}-$headers_length-2;
      $r->{'payload_length'}=$content_length;
      #print $r->{'start_payload_byte'}, ' ', $r->{'payload_length'},"\n";
      #exit;
    }
    else {
      $r->{$type}->{'size'}=$ret;
      $r->{$type}->{'status'}=$status;
      $r->{$type}->{'message'}=$message;
      $r->{$type}->{'header'}=$headers;
      $r->{'start_payload_byte'}=$r->{'start_body_byte'}+$ret;
      ## take account of the blank line
      if($r->{'body_length'}-$ret) {
	$r->{'payload_length'}=$r->{'body_length'}-$ret-2;
	## check for the next char. Fixme this is a bleeding mess
	my $end_payload_byte=$r->{'start_payload_byte'}+$r->{'payload_length'};
	if(ord $r->check_next_char($fh,$end_payload_byte) ne 13) {
	  $r->{'payload_length'}++;
	  $end_payload_byte=$r->{'start_payload_byte'}+$r->{'payload_length'};
	  $end_payload_byte=$r->{'start_payload_byte'}+$r->{'payload_length'};
	  if(ord $r->check_next_char($fh,$end_payload_byte) ne 13) {
	    $r->{'payload_length'}++;
	  }
	}
      }
    }
  }
  elsif($r->{'type'} eq 'warcinfo') {
    my $i=Warc::Warcinfo->new({'body' => $body});
    $i->parse();
    $r->{$type}=$i;
  }
  else {
    $r->{$type}=$body;
  }
  delete $r->{'body'};
}

sub check_next_char {
  my $r=shift;
  my $fh=shift;
  my $pos=shift;
  ## save the start position
  my $start_pos=$fh->tell();
  my $char='';
  $fh->seek($pos,0);
  $fh->read($char,1);
  $fh->seek($start_pos,0);
  return $char;
}


1;
