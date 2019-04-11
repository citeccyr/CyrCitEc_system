
package BundleXml;


# USAGE:
# my $x = new BundleXml;  $x->GetHah('1qT9jm');
# 

use strict;
use warnings;

#use LWP::Simple;
use MyXMLParser;
use Data::Dumper;
#use Template;
#use Cec::Paths;
use Cyrcitec;
use File::Slurper;



my $code;
my $hs;
my $dir_xml;
#my $type = 'analysis';

sub test {
  _init(@_);
  my $dirs=$Cec::Paths::dirs;
  return $code.'--'.Dumper($dirs).'--'.GetPath(); # .Dumper(GetHashFirstReference ());
}

sub _init
{
  my $self = shift;
  my $c = shift;
  $code = $c if $c;
  undef $hs if $c;
  my $o = shift;
  #$type = $o->{'type'} if $o && $o->{'type'} && ($o->{'type'} eq 'repec_bundles' || $o->{'type'} eq 'bundles');
  $dir_xml = $o->{'dir_xml'} if $o && $o->{'dir_xml'};
}


sub new
{
 _init(@_);
 return shift;
}

sub GetHash
{
  _init(@_);
  if(!$hs) 
  {
    my $path = GetPath();
#print $path;
    if($path) {
      my $xmlt = &File::Slurper::read_text($path);
      my $parser = new MyXMLParser('content' => $xmlt);
      $hs = $parser->GetHashFromXmlFile();
    }
  }
  return $hs;
}


sub GetPath
{
  _init(@_);
  #my $dirs=$Cec::Paths::dirs;
	#print Dumper($dirs);
  #return $dirs->{$type.'_xml'}.'/'.$code.'.xml';
  return $dir_xml.'/'.$code.'.xml'; 
}


#sub GetHashByCode
#{
#    my $code = $_[0];
#    my $xml = get 'http://cirtec.ranepa.ru/analysis/xml/'.$code.'.xml';
#    return GetHashByContent($xml);
#}

sub GetTitle
{
  _init(@_);
  my $info = GetHashFirstReference();
  my $title = $info->{'author'}.' ';
  $title .= '('.$info->{'year'}.') ' if $info->{'year'};
  $title .= $info->{'title'};
  return $title;
}

sub GetHashFirstReference 
{
    _init(@_);
    my $hs = GetHash();
#    my $res;
   return $hs->{'bundle'}->[0]->{'ref'}->[0]->{'reference'}->[0];
}

sub GetHashExt # ByContent
{
    _init(@_);
    my $hs = GetHash();
    my $res;
    my $hsi = $hs->{bundle}->[0];
    my $bunshid = $hsi->{bunshid};
    my $tcount = 0;
    my $pcount = 0;
    my @ints = (0,0,0,0,0);
    
    foreach my $itm (@{$hsi->{ref}}) {
	$pcount++;
	my $found_in = $itm->{found_in};
	my $pend = $itm->{reference}->[0]->{start} - ($itm->{reference}->[0]->{num}-1)*200;
	$res->{$bunshid}->{title} = $itm->{reference}->[0]->{title} if !$res->{$bunshid}->{title};
	$res->{$bunshid}->{author} = $itm->{reference}->[0]->{author} if !$res->{$bunshid}->{author};
	$res->{$bunshid}->{year} = $itm->{reference}->[0]->{year} if !$res->{$bunshid}->{year};
	#$res->{$bunshid}->{num} = $itm->{reference}->[0]->{num} if !$res->{$bunshid}->{num};
	#$res->{$bunshid}->{start} = $itm->{reference}->[0]->{start} if !$res->{$bunshid}->{start};
	#$res->{$bunshid}->{end} = $itm->{reference}->[0]->{end} if !$res->{$bunshid}->{end};

	$res->{$bunshid}->{pubs}->{$itm->{found_in}} = {
	    #num => $itm->{reference}->[0]->{num}, start => $itm->{reference}->[0]->{start}, end => $itm->{reference}->[0]->{end}, author => $itm->{reference}->[0]->{author}, year => $itm->{reference}->[0]->{year}, doi => $itm->{reference}->[0]->{doi}
	     pub_end => $pend
	    , num => $itm->{reference}->[0]->{num}
	    , start => $itm->{reference}->[0]->{start}
	    , end => $itm->{reference}->[0]->{end}
	};
	my @dt = (0,0,0,0,0);
	my @refs = ([],[],[],[],[]);
	foreach my $k (@{$itm->{intextref}}) {
	    my $fl = 5*$k->{Start}->[0]/$pend;
	    my $num = int($fl) < 0 ? 0 : int($fl);
	    if($num > 4) { $num = 4; }
	    $dt[$num] += 1;
	    $ints[$num] += 1;
	    push @{$refs[$num]}, $k;
	    $tcount++;
	}
	
	#add authors el, title:
	my $authors = ''; my $tcnt = 0;
	foreach my $k (@{$itm->{citer}->[0]->{author}}) {
	    $tcnt++;
	    if($tcnt == 1) { $authors .= $k; }
	    elsif($tcnt == 2) { $authors .= ', '.$k; }
	    elsif($tcnt == 3) { $authors .= ' et al.'; }
	    #print ' '.$k;
	    
	}
	#exit;
	$res->{$bunshid}->{pubs}->{$itm->{found_in}}->{intextsummary} = join '/', @dt;
	$res->{$bunshid}->{pubs}->{$itm->{found_in}}->{intextref} = \@refs;
	$res->{$bunshid}->{pubs}->{$itm->{found_in}}->{authors} = $authors;
	$res->{$bunshid}->{pubs}->{$itm->{found_in}}->{title} = $itm->{citer}->[0]->{title}->[0];
	$res->{$bunshid}->{pubs}->{$itm->{found_in}}->{year} = $itm->{citer}->[0]->{year}->[0];
    }
    $res->{$bunshid}->{paperscount} = keys %{$res->{$bunshid}->{pubs}};
    $res->{$bunshid}->{intextcount} = $tcount;
    $res->{$bunshid}->{intextsummary} = join '/', @ints;
#print Dumper($res); exit;
    return $res;
}

sub GetIntextRef
{
   my $self = shift;
   my @parts = @_;
   my $res; #my $rf;
   my $hs = GetHash();

  #print Dumper(\@parts);
   my @arr = @{$hs->{'bundle'}->[0]->{'ref'}};
   foreach my $rf (@arr)
   {
     my $found = 0;
     if($parts[0] eq $rf->{'found_in'} && $parts[1] eq $rf->{'num'})
     {
#       if($rf->{'reference'}) { $res->{'title'} = $rf->{'reference'}->[0]->{'author'}.' ('.$rf->{'reference'}->[0]->{'year'}.') '.$rf->{'reference'}->[0]->{'title'}; }
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



sub Get__IntextRefs_tmp
{
#    _init(@_);
   my $self = shift;
   my @parts = @_;
   my $res; #my $rf;
    my $hs = GetHash();

   my @arr = @{$hs->{'bundle'}->[0]->{'ref'}};
   foreach my $rf (@arr)
   {
    foreach my $it (@{$rf->{'intextref'}})
    {
     my $found = 0;
print $parts[0] .'--'. $rf->{'found_in'}."\n";
     if($parts[0] eq $rf->{'found_in'} && ($parts[1] eq $it->{'Start'}->[0] || !$parts[1]))
     {
  print "?????";
exit;
       #if($rf->{'reference'}) { $res->{'title'} = $rf->{'reference'}->[0]->{'author'}.' ('.$rf->{'reference'}->[0]->{'year'}.') '.$rf->{'reference'}->[0]->{'title'}; }
       my $rarr;
       foreach my $intxt (@{$rf->{'intextref'}})
       {
#         $intxt->{'found'} = 0;
#         if($intxt->{'Start'}->[0] eq $parts[2]) {
#            $res->{'intextref'} = $intxt;
#            if(!$res->{'citer'}) { $res->{'citer'} = $rf->{'citer'}->[0]; }
#            $intxt->{'found'} = 1;
#         }
#         push @$rarr, $intxt;
       }
#       $rf->{'intextref'} = $rarr;
#       if(!$res->{'citer'}) { $res->{'citer'} = $rf->{'citer'}->[0]; }
     }
    }
   }
   #$res->{'handle'} = $parts[0];
   return $res;

}


1;