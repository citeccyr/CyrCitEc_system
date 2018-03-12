package Warc::Constants;

use strict;
use warnings;

## some constants
our $payload_search='^WARC-Payload-Digest: sha1:';
our $version='WARC/1.0';
our $type_search='^WARC-Type:\s+';
our $header_search='^([^:]+):\s+(.*)$|';

our $type;
$type->{'warcinfo'}=1;
$type->{'metadata'}=1;
$type->{'resource'}=1;
$type->{'request'}=1;
$type->{'response'}=1;

## the standard says "Because new fields may be defined in extensions to the core WARC format,
## WARC processing software shall ignore fields with unrecognized names." I nevertheless
## check whether the header name is valid.
our $field;
$field->{'WARC-Type'}=1;
$field->{'WARC-Record-ID'}=1;
$field->{'WARC-Date'}=1;
$field->{'Content-Length'}=1;
$field->{'Content-Type'}=1;
$field->{'WARC-Concurrent-To'}=1;
$field->{'WARC-Block-Digest'}=1;
$field->{'WARC-Payload-Digest'}=1;
$field->{'WARC-IP-Address'}=1;
$field->{'WARC-Refers-To'}=1;
$field->{'WARC-Target-URI'}=1;
$field->{'WARC-Truncated'}=1;
$field->{'WARC-Warcinfo-ID'}=1;
$field->{'WARC-Filename'}=1;                # warcinfo only
$field->{'WARC-Profile'}=1 ;                # revisit only
$field->{'WARC-Identified-Payload-Type'}=1;
$field->{'WARC-Segment-Origin-ID'}=1;       # continuation only
$field->{'WARC-Segment-Number'}=1;
$field->{'WARC-Segment-Total-Length'}=1;    # revisit only

1;
