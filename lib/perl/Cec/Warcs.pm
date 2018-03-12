package Cec::Warcs;

use Cec::Paths;
use URI::Escape;

our $handle_from_warc = sub {
  my $warc_file=shift;
  my $handle=$warc_file;
  my $warc_path=$Cec::Paths::dirs->{'warc'};
  $handle=~s|$warc_path/*||;
  $handle=~s|\.warc$||;
  $handle=~s|/|:|;
  $handle=~s|/|:|;
  $handle=~s|/|:|;
  $handle=~s|/[^/]+$||;
  $handle=uri_unescape($handle);
  return $handle;
};

## fixme: should not be here
our $handle_from_peren = sub {
  my $warc_file=shift;
  my $handle=$warc_file;
  my $peren_path=$Cec::Paths::dirs->{'peren'};
  $handle=~s|$peren_path/*|| or die;
  $handle=~s|/|:|;
  $handle=~s|/|:|;
  $handle=~s|/|:|;
  $handle=~s|/[^/]+$||;
  $handle=uri_unescape($handle);
  return $handle;
};


1;
