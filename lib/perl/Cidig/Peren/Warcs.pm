package Cidig::Peren::Warcs;

require Exporter;
@ISA = qw(Exporter Cidig::Peren);
@EXPORT_OK = qw(peren_dir_from_warc_dir
		deal_with_warcs
		do_loud
		report_on_missing_in_warcs
		sheet2text
		warc2text);

use Carp qw(confess);
use Data::Dumper;
use File::Path;
use File::Temp;

use strict;
use warnings;

my $count_warcs_with_pdfs=0;

sub deal_with_warcs {
  my $p=shift;
  my $params=shift;
  my $warc_dir=$p->{'warc_dir'} // confess "I need this defined here.";
  my $warcs=&Cidig::Files::load_from_directory($warc_dir,'\.warc$');
  my $count_warcs=0;
  foreach my $warc (@$warcs) {
    if($params->{'only_file'}) {
      my $only=$params->{'only_file'};
      if(not $warc=~m|$only$|) {
	next;
      }
    }
    #print "I look at $warc\n";
    $p->warc2text($warc);
    $count_warcs++;
  }
  if($p->{'verbose'}) {
    print "I saw $count_warcs warcs\n";
  }
  print "I saw $count_warcs warcs, $count_warcs_with_pdfs of them have a PDF.\n";
}

sub report_on_missing_in_warcs {
  my $p=shift;
  my $params=shift;
  my $warc_dir=$p->{'warc_dir'} // confess "I need this defined here.";
  my $warc_files=&Cidig::Files::load_from_directory($warc_dir,'\.warc$');
  my $count_warcs=0;
  foreach my $warc_file (@$warc_files) {
    my $w=Warc::File->new({'file'=>$warc_file});
    my $pdfs=$w->get_pdfs();
    if(defined($pdfs->[0])) {
      next;
    }
    $w->report_on_missing('Futli');
  }
}

sub get_handle_from_warc {
#  my $p=shift;
  my $file=shift;
  if(not $file) {
    die "I need a file here.";
  }
  if(not -f $file) {
    die "I don't see your file $file";
  }
  my $grep=`grep -a Paper-Id $file`;
  chomp $grep;
  $grep=~m|"Paper-Id: (\S+)"| or die "I don't see the handle in $grep";
  my $handle=$1;
  return $handle;
}

sub get_handle_from_file_name {
  my $p=shift;
  my $file=shift;
  if(not $file) {
    die "I need a file here.";
  }
  if(not -f $file) {
    die "I don't see your file $file";
  }
  my $paper_dir=$p->peren_dir_from_warc_dir($file);
  my $grep=`grep -a Paper-Id $file`;
  chomp $grep;
  $grep=~m|"Paper-Id: (\S+)"| or die "I don't see the handle in $grep";
  my $handle=$1;
  return $handle;
}

sub do_loud {
  my $p=shift;
  my $s=shift;
  if($p->{'verbose'}) {
    print "I run '$s' ...";
  }
  system($s);
  if($p->{'verbose'}) {
    print " done\n"
  }
}

## FixMe: I want something more elegant than this
sub sheet2text {
  my $p=shift;
  my $count=shift;
  my $lestfi=shift;
  ## pdfminer first
  my $fh = File::Temp->new();
  my $tmp_file = $fh->filename();
  my $out_bana="$count.pdfminer.txt";
  my $out_fufi=$p->{'paper_dir'}.'/'.$out_bana;
  ## do we need to do this again?
  if($p->i_need_new($out_fufi) and not $p->{'json_only'}) {
    ## it is not there, so we save it.
    if(not -f $tmp_file or -z $tmp_file) {
      $lestfi->save_file($tmp_file);
    }
    ## this should have created $tmp_file
    my $log="$out_fufi.log";
    my $err="$out_fufi.err";
    my $s=$p->{'bin'}->{'pdfminer'}." -t text -o $out_fufi $tmp_file > $log 2> $err";
    $p->do_loud($s);
  }
  ## poppler second
  $out_bana="$count.poppler.txt";
  $out_fufi=$p->{'paper_dir'}.'/'.$out_bana;
  ## do we need to do this again?
  if($p->i_need_new($out_fufi) and not $p->{'json_only'}) {
    #my $out_xml="$out_file.xml";
    if(not -f $tmp_file or -z $tmp_file) {
      $lestfi->save_file($tmp_file);
    }
    my $log="$out_fufi.log";
    my $err="$out_fufi.err";
    my $s=$p->{'bin'}->{'poppler'}." $tmp_file $out_fufi > $log 2> $err";
    $p->do_loud($s);
  }
  ## pdf-stream text
  $out_bana="$count.pdf-stream.txt";
  $out_fufi=$p->{'paper_dir'}.'/'.$out_bana;
  ## do we need to do this again?
  if($p->i_need_new($out_fufi) and not $p->{'json_only'}) {
   #my $out_xml="$out_file.xml";
    if(not -f $tmp_file or -z $tmp_file) {
      $lestfi->save_file($tmp_file);
    }
    my $log="$out_fufi.log";
    my $err="$out_fufi.err";
    my $s=$p->{'bin'}->{'pdf-stream'}." -t text $tmp_file $out_fufi > $log 2> $err";
    $p->do_loud($s);
  }
  ## pdf-stream json
  $out_bana="$count.pdf-stream.json";
  $out_fufi=$p->{'paper_dir'}.'/'.$out_bana;
  ## do we need to do this again?
  if($p->i_need_new($out_fufi)) {
    #my $out_xml="$out_file.xml";
    if(not -f $tmp_file or -z $tmp_file) {
      #print "tmp_file is $tmp_file\n";
      $lestfi->save_file($tmp_file);
    }
    if(-z $tmp_file) {
      confess "$tmp_file is empty";
    }
    my $log="$out_fufi.log";
    my $err="$out_fufi.err";
    my $s=$p->{'bin'}->{'pdf-stream'}." -t json $tmp_file $out_fufi > $log 2> $err";
    $p->do_loud($s);
  }
  return 1;
}

sub report_on_warc {
  my $p=shift;
  my $w=shift;
  my $warc_file=shift;
  my $pdfs=$w->get_pdfs();
  my $count_pdfs=scalar($pdfs);
  print "I seed $count_pdfs pdfs.\n"
}

sub warc2text {
  my $p=shift;
  my $warc_file=shift;
  if($p->{'verbose'}) {
    print "doing $warc_file\n";
  }
  my $paper_dir=$p->peren_dir_from_warc_dir($warc_file);
  ## this depends on the found file
  $p->{'paper_dir'}=$paper_dir;
  if(not -d $paper_dir)  {
    mkpath($paper_dir);
  }
  my $w=Warc::File->new({'file'=>$warc_file});
  #my $pls=$w->payloads('application/pdf','Futli');
  ## get pdf as payloads or resources
  my $pls=$w->get_pdfs();
  my $count_pls=0;
  while($pls->[$count_pls]) {
    my $lestfi=Warc::Lestfi->new($pls->[$count_pls]);
    $p->sheet2text($count_pls,$lestfi);
    $count_pls++;
  }
  if($count_pls) {
    $count_warcs_with_pdfs++;
  }
  ## approach via resources
  #my $res=$w->resources('application/octet-stream','application/pdf','Futli');
  #my $count_res=0;
  #while($res->[$count_res]) {
  #  my $lestfi=Warc::Lestfi->new($res->[$count_res]);
  #  $p->sheet2text($count_res,$lestfi);
  #  $count_res++;
  #}
}

1;
