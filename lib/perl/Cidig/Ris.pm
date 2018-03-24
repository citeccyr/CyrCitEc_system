package Cidig::Ris;

use strict;
use warnings;

use Carp qw(confess);
use URI::Escape;

our $id2file;
$id2file->{'RePEc'}=sub {
  my $id=shift // confess "I need an identifier here.";
  my $file='RePEc';
  $file .= '/' .substr($id,6,3);
  $file .= '/' .substr($id,10,6);
  $file .= '/' . uri_escape(substr($id,17));
  return $file;
};

$id2file->{'spz'}=sub {
  my $id=shift // confess "I need an identifier here.";
  my $file=$id;
  $file=~s|repec|RePEc|i;
  ## change the first three :
  $file=~s|:|/|;
  $file=~s|:|/|;
  $file=~s|:|/|;
  ## take the part until the /
  $file=substr($file,0,$-[0]+1);
  $file.=uri_escape(substr($id,$-[0]+1));
  return $file;
};

our $file2id;
$file2id->{'RePEc'}=sub {
  my $file=shift // confess "I need an identifier here.";
  my $id='RePEc:';
  $id .= ':' .substr($file,6,3);
  $id .= '/' .substr($file,10,6);
  $id .= '/' . uri_unescape(substr($file,17));
  return $id;
};

$file2id->{'spz'}=sub {
  my $file=shift // confess "I need an identifier here.";
  my $id=$file;
  ## change the first three :
  $id=~s|/|:|;
  $id=~s|/|:|;
  $id=~s|/|:|;
  ## take the part until the /
  my $pos=$-[0];
  my $handle=substr($id,0,$pos);
  $handle.=uri_unescape(substr($id,$pos));
  return $handle;
};

our $input2id;
$input2id->{'spz'}=sub {
  my $file=shift // confess "I need an identifier here.";
  chomp $file;
  my $id=$file;
  $id=~s|\.xml$||;
  ## change the first three :
  $id=~s|/|:|;
  $id=~s|/|:|;
  $id=~s|/|:|;
  #my $id1=$id;
  $id=~s/^([^:]{3}):/RePEc:$1:/;
  $id=~s|^neicon:|spz:neicon:|;
  $id=~s|^rnp:|RePEc:rnp:|;
  #die "$id1 $id";
  ## take the part until the /
  #$id=substr($id,0,$-[0]+1);
  #$id.=uri_unescape(substr($id,$-[0]+1));
  return $id;
};

$file2id->{'spz_OLD'}=sub {
  my $file=shift // confess "I need an identifier here.";
  my $id=$file;
  $id=~s|repec|RePEc|i;
  ## change the first three :
  $id=~s|/|:|;
  $id=~s|/|:|;
  $id=~s|/|:|;
  ## take the part until the /
  $id=substr($id,0,$-[0]+1);
  $id.=uri_unescape(substr($id,$-[0]+1));
  return $id;
};

our $preSelect;
$preSelect->{'RePEc'}=sub {
  my $i=shift;
  my $sd  = $i->{'dbh'}->prepare("select scodigo from FUENTE");
  my $ss = $i->{'dbh'}->prepare("select docid from ESPUBLICADO where scodigo = ?");
  my $sn = $i->{'dbh'}->prepare("select docid,nombre,fecha from ESTA where docid = ?");
  my $sas = $i->{'dbh'}->prepare("select t1.scodigo from FUENTE as t1, ESPUBLICADO as t2 where t1.scodigo = t2.scodigo and t2.docid = ?");
  return ($sd,$sn,$ss,$sas);
};

our $fragaCodes =
  {
   baddocument => 'error_wrongFormat',
   binaryfile => 'error_wrongFormat',
   done => 'ok_references',
   downerror => 'error_futliNotFound',
   foreign => 'error_wrongFormat',
   incompatibleformat => 'error_wrongFormat',
   linked => 'end_linked',
   nofulltext => 'error_noFutli',
   nonenglish => 'error_wrongFormat',
   noreferences => 'error_noReferences',
   pstotexterror => 'error_conversionFailed',
   ready => 'ok_txtReady',
   restricted => 'error_docExcluded',
   resume => 'error_wrongFormat',
   spacefree => 'error_wrongFormat',
   tooshort => 'error_wrongFormat',
   tmp => 'error_wrongFormat',
   inprocess => 'error_wrongFormat',
   undownloaded => 'ok_docNotYetDownloaded',
   wrongnumberofreferences => 'error_wrongReferences'
  };



1;
