#!/usr/bin/perl
use strict;
use warnings;

use Cec::Paths;
use File::Slurper qw(read_text);
use JSON::XS;
use lib '../Modules'; # no need from web request

use MyXMLParser;
#use LWP::Simple;
use Data::Dumper;
use Cyrcitec;
#use GT::Template;
#use Template;
use CGI;
use URI::Escape;
use Encode;
use BundleXml;

#my $files=$Cec::Paths::files;
my $dirs=$Cec::Paths::dirs;
my $que = new CGI();
 

print "Content-type: text/html; charset=utf-8\n\n";
print get_phrase() if $que->param('phrase') && !$que->param('w');
print get_ref_phrases() if $que->param('phrase') && $que->param('w');
print get_topic() if $que->param('topic');


sub get_topic
{
  my $code = $que->param('topic');
  my $json = &File::Slurper::read_text($dirs->{'www_w2v'}.'/topic_output.json');
  my $jdata = JSON::XS->new->decode ($json); # = decode_json($json_t);
  my $hs = $jdata->{$code};
  my @data;
#me($hs);

  my $bndl = new BundleXml($code);
  my $xhs = $bndl->GetHash();

#  my $xmlf = $dirs->{'analysis_xml'}.'/'.$code.'.xml';
 # my $xmlt = &File::Slurper::read_text($xmlf);
 # my $parser = new MyXMLParser('content' => $xmlt, 'encoding' => 'cp1251');
 # my $xhs = $parser->GetHashFromXmlFile();

  my $title = $bndl->GetTitle();

  for(my $i = 0; $i < @{$hs}; $i++) {
    for(my $j = 0; $j < @{$hs->[$i]}; $j++) {

     #####      my $rs = get_by_ref_key($xhs, $hs->[$i]->[$j]);

      my @parts = split /_/, $hs->[$i]->[$j]->{'ref_key'};
      if($hs->[$i]->[$j]->{'ref_key'} =~ /^([^\n]+)_([^_]+)_([^_]+)$/) { @parts = ($1, $2, $3); }
      my $rs = $bndl->GetIntextRef(@parts);

      if($rs->{'citer'}) { $hs->[$i]->[$j]->{'author'} = $rs->{'citer'}->{'author'}->[0]; $hs->[$i]->[$j]->{'title'} = $rs->{'citer'}->{'title'}->[0]; $hs->[$i]->[$j]->{'year'} = $rs->{'citer'}->{'year'}->[0]; }
      if($rs->{'intextref'}) { $hs->[$i]->[$j]->{'Suffix'} = $rs->{'intextref'}->{'Suffix'}->[0]; $hs->[$i]->[$j]->{'Prefix'} = $rs->{'intextref'}->{'Prefix'}->[0]; }
      #if(!$title && $rs->{'title'}) { $title = $rs->{'title'}; }
      $hs->[$i]->[$j]->{'handle'} = $rs->{'handle'};
      #$hs->[$i]->[$j]->{'citer'} = $rs->{'citer'};
      #$hs->[$i]->[$j]->{'intextref'} = $rs->{'intextref'};
      push @data, $hs->[$i]->[$j];
    }
  }

  my $noref = get_other_refs($xhs);
#me(\@data, 1);

  $json = &File::Slurper::read_text($dirs->{'www_w2v'}.'/topics_freq.json');
  $jdata = JSON::XS->new->decode ($json);
  $hs = $jdata->{$code};
  #me($hs);

  my $shs;
  foreach my $name (keys %$hs) {
    $hs->{$name}->{'name'} = $name;
    #my $ln = $hs->{$name};
    $shs->{$name} = $hs->{$name}->{freq};
  } 

  my @arr;
  foreach my $obj (sort {$shs->{$b} <=> $shs->{$a} } keys %$shs) {
     #me($hs->{$obj});
     push @arr, $hs->{$obj};
  }

#  me($shs);
#    %shs{$hs->{$name}} = $hs->{$name}->{'freq'};
  #}
#me(\%shs);
  
  Cyrcitec::parseTemplate('topic.html',  { data => \@data, freqs => \@arr, title => $title, noref => $noref } );
}

sub __get__by_ref_k__ey
{
   my ($hs, $ref) = @_;
   my $res;
   my @parts = split /_/, $ref->{'ref_key'};
   if($ref->{'ref_key'} =~ /^([^\n]+)_([^_]+)_([^_]+)$/) { @parts = ($1, $2, $3); }
    #me($ref);

   my @arr = @{$hs->{'bundle'}->[0]->{'ref'}};
   foreach my $rf (@arr) 
   {
     my $found = 0;
     if($parts[0] eq $rf->{'found_in'} && $parts[1] eq $rf->{'num'}) 
     {
       if($rf->{'reference'}) { $res->{'title'} = $rf->{'reference'}->[0]->{'author'}.' ('.$rf->{'reference'}->[0]->{'year'}.') '.$rf->{'reference'}->[0]->{'title'}; }
       my $rarr;
       foreach my $intxt (@{$rf->{'intextref'}}) 
       {
         $intxt->{'found'} = 0;
         if($intxt->{'Start'}->[0] eq $parts[2]) {
            $res->{'intextref'} = $intxt;
            if(!$res->{'citer'}) { $res->{'citer'} = $rf->{'citer'}->[0]; }
            $intxt->{'found'} = 1;
         }
         push @$rarr, $intxt;
       }
       $rf->{'intextref'} = $rarr;
       if(!$res->{'citer'}) { $res->{'citer'} = $rf->{'citer'}->[0]; }
     }
   }
   $res->{'handle'} = $parts[0];
   return $res;
}

sub get_other_refs {
  my $hs = $_[0];
  my @arr = @{$hs->{'bundle'}->[0]->{'ref'}};
  my $rarr;
  foreach my $rf (@arr) 
  {
    foreach my $intxt (@{$rf->{'intextref'}}) 
    {
      if(!$intxt->{'found'}) { 
        my $itm;
        $itm->{'Suffix'} = $intxt->{'Suffix'}->[0];
        $itm->{'Prefix'} = $intxt->{'Prefix'}->[0];
        my $a = '';
        foreach my $au (@{$rf->{'citer'}->[0]->{'author'}}) { $a .= ', ' if $a; $a .= $au; }
        $itm->{'author'} = $a; #$rf->{'reference'}->[0]->{'author'};
        $itm->{'year'} = $rf->{'citer'}->[0]->{'year'}->[0];
        $itm->{'title'} = $rf->{'citer'}->[0]->{'title'}->[0];
	$itm->{'handle'} = $rf->{'found_in'};
	push @$rarr, $itm; 
      }
    }
  }  
# me($rarr, 1);
  return $rarr;
}

sub get_phrase
{
  my $code = $que->param('phrase');
  my $json = read_text($dirs->{'www_w2v'}.'/2-3-4-5-6_grams_v3.json');

#  my $json = &File::Slurper::read_text($dirs->{'www_w2v'}.'/2-3-4-5-6_grams_v3.json'); #3_grams_v2.json');
#  my $jdata = decode_json($json);
#  my $json_t = &File::Slurper::read_text($dirs->{'www_w2v'}.'/topic_output.json');
#  my $jdata_t = JSON::XS->new->decode ($json_t); # = decode_json($json_t);

  my $jdata = decode_json($json);
  my $hs = $jdata->{$code};

  Cyrcitec::parseTemplate('phrases.html',  { data => $hs, code => $code } );
}

sub get_phase {
  my ($id, $jdata) = @_;
  my $w = 'none';
  if($jdata->{$id}) {
    my @phs = @{$jdata->{$id}->{'3norm'}};
    if(@phs) {
      $w = $phs[0]->{'w'}.' ('.$phs[0]->{'n'}.')'
    }
  }
  return $w;
}


sub get_ref_phrases
{
  my $code = $que->param('phrase');
  my $w = $que->param('w');
#print $w;
#  my $rh = get_query_params();
#  $w = ''.$rh->{'w'};
#$w = utf8::encode($w);
$w = decode('utf8', $w);

  my $xmlf = $dirs->{'analysis_xml'}.'/'.$code.'.xml';
  my $xmlt = &File::Slurper::read_text($xmlf);
  my $parser = new MyXMLParser('content' => $xmlt, 'encoding' => 'cp1251');
  my $hs = $parser->GetHashFromXmlFile();
#me($hs);

  my @arr = @{$hs->{'bundle'}->[0]->{'ref'}};
#me(\@arr);
  my $t = @arr;
  #print "===".$t."\n";
  my $res;
  foreach my $rf (@arr) 
  {
#print ( $rf->{'found_in'}."\n") ;
     #my $found = 0;
     #if($parts[0] eq $rf->{'found_in'} && $parts[1] eq $rf->{'num'}) 
    if($rf->{'intextref'}) {
      my @int = @{$rf->{'intextref'}};
      foreach my $in (@int) 
      {
        my $sfx = lc($in->{'Suffix'}->[0]);
        $sfx =~ s/[ \t\n]+/ /mgi;
        my $pfx = lc($in->{'Prefix'}->[0]);
        $pfx =~ s/[ \t\n]+/ /mgi;
        if($sfx =~ /$w/mgi || $pfx =~ /$w/mgi) 
        {
#print $w.'**';
          my $itm;
          $itm->{'title'} = $rf->{'citer'}->[0]->{'title'}->[0];
          $itm->{'year'} = $rf->{'citer'}->[0]->{'year'}->[0];
	  $itm->{'author'} = '';
          $itm->{'Start'} = $in->{'Start'}->[0];
          $itm->{'Prefix'} = $in->{'Prefix'}->[0];
              $itm->{'Prefix'} =~ s/[ \t\n]+/ /mgi; $itm->{'Prefix'} =~ s/$w/<b>$w<\/b>/mgi;
          $itm->{'Suffix'} = $in->{'Suffix'}->[0];
              $itm->{'Suffix'} =~ s/[ \t\n]+/ /mgi; $itm->{'Suffix'} =~ s/$w/<b>$w<\/b>/mgi;
          $itm->{'Exact'} = $in->{'Exact'}->[0];
          #$itm->{'Start'} = $in->{'Start'}->[0];
         # print ( $rf->{'found_in'}." $author\n") ; #.$w.'='.utf8::is_utf8($w).' -- '. utf8::is_utf8($sfx)." ".$sfx." ^^^^^".$rf->{'citer'}->[0]->{'title'}->[0]."\n");
          if($rf->{'citer'}->[0]->{'author'}) {
            $itm->{'author'} = join ', ', @{$rf->{'citer'}->[0]->{'author'}};
          }
          #me($itm);
          push @$res, $itm;
        }
      }
    }
  }
#me($res->[5]);
  Cyrcitec::parseTemplate('phrases_ref.html',  { data => $res } );
}





sub parseTemplate
{
  my $data = $_[0];
  my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
    DEBUG => 0,
  })  || die "$Template::ERROR\n";

  my $vars = {
    root => $data
  };

  $tt->process('phrases.html', $vars)
    || die $tt->error(), "\n";
  return ;
}

sub me
{
  if($ENV{'REMOTE_ADDR'} eq '40.71.98.81' || $ENV{'REMOTE_ADDR'} eq '85.118.225.254') { print Dumper($_[0]); }
  exit if $_[1];
# print Dumper(\%ENV);
}


sub get_query_params
{
  my $RequestHash;
  if($ENV{"QUERY_STRING"}) {
    my @TempArray=split("&", $ENV{"QUERY_STRING"});
    foreach my $item (@TempArray) {
      #print $item."\n";
         my ($Key, $Value)=split("=", uri_unescape($item)); #need to fix this to work with more than one "=" in the value
        $RequestHash->{lc($Key)}=$Value; 
    }
  }
print "???";
  return $RequestHash;
}

sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    return $s;
}

sub urldecode {
    my $s = shift;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $s =~ s/\+/ /g;
    return $s;
}