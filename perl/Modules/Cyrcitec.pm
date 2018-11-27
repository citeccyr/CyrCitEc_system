
package Cyrcitec;

use LWP::Simple;
use MyXMLParser;
use Data::Dumper;
use Template;
use Cec::Paths;

sub GetHByCode {
  my $code = $_[0];
}

sub test {
}


#my $ref = getFileDataByCode('hEDJmg');
#parseTemplate($ref);

sub parseTemplate
{
  #my $data = $_[0];
  my ($file, $vars) = @_;
  my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
    DEBUG => 0,
  })  || die "$Template::ERROR\n";

  #my $vars = { root => $data };
  $tt->process($file, $vars)
    || die $tt->error(), "\n";
  return ;
}



sub GetFileContent
{
    my $filename = $_[0];
    open(FH, '<', $filename) or die $!;
    my $xml = '';
    while(<FH>){
	$xml .= $_;
    }
    close(FH);
    return $xml;
}

sub SaveFileContent
# file , content
{
   if($_[0] ne "") {
        open SFCF, ">".$_[0];
        print SFCF $_[1];
        close SFCF;
   }
}

sub GetHashByFilePath
{
    return GetHashByContent(GetFileContent($_[0]));
}


sub GetHashByCode
{
    my $code = $_[0];
    my $xml = get 'http://cirtec.ranepa.ru/analysis/xml/'.$code.'.xml';
    return GetHashByContent($xml);
}

sub GetHashByContent
{
    my $xml = $_[0];
    #my $code = $_[0];
    #my $xml = get 'http://cirtec.ranepa.ru/analysis/xml/'.$code.'.xml';
    #print " -- ".'http://cirtec.ranepa.ru/analysis/xml/'.$code.'.xml';
    my $parser = new MyXMLParser('content' => $xml, 'encoding' => 'cp1251');
    my $hs = $parser->GetHashFromXmlFile();
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
	    # http://cirtec.ranepa.ru/analysis/xml/ro6x8q.xml
	    # <reference num="64" start="84229" end="84378"  ==> pend = 71629
	    #   <Start>72644</Start>
	    #if($num > 4) { 
	    #	print Dumper($k)."***".$fl."* $pend *(" . (int($fl) < 0 ? 0 : int($fl)) . ")\n"  .$itm->{found_in}."\n"
	    #	    . $itm->{reference}->[0]->{num} .'---'.$itm->{reference}->[0]->{start}.' == '.$k->{Start}->[0];
	    #}
	    #$res->{$bunshid}->{$itm->{found_in}}->{xxx} .= '   '.$k->{Start}->[0].'^'.$fl.'=>'. int($fl);
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

=comment

#getFirstReference($xml, $found_in); 
sub getFirstReference 
{
    my ($cont, $found_in) = @_;
    my @parts = split  /<\/ref>/, $cont;
    for(my $i = 0; $i < @parts; $i++) {
	if($parts[$i] =~ /found_in="$found_in"/) {
	    print $parts[$i]; exit;
	}
    }
    #if($cont =~ /found_in="$found_in"[^>]*>[^<]*<reference/) {
    #}
    print $parts[0]; exit;
#    print $cont; exit;
}

sub getXmlContent
{

    my $str = '';
    my $ref = getFileDataByCode('hEDJmg');
    my $id = (keys $ref)[0];
    $str .= '<ol>';
    foreach my $pub (keys %{$ref->{$id}->{pubs}}) {
	my $cur = $ref->{$id}->{pubs}->{$pub};
	$str .= '<li style="margin: 20px">'.$pub.'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>'.$cur->{'intextsummary'}.'</b>';
	    $str .= '<ul>';
	    for(my $i = 0; $i < 5; $i++) { #  (keys %{$ref->{$id}}) {
		$str .= '<li><b>#'.($i+1).'</b>';
		my @arr = @{$cur->{intextref}->[$i]};
		if(@arr == 0) { $str .= ' No data'; }
		else {
		   $str .= '<ul>';
		   for(my $j = 0; $j < @arr; $j++) {
		    $str .= '<li>';
		    $str .= ' start: '.$arr[$j]->{Start}->[0].'<br/>';
		    $str .= ' end: '.$arr[$j]->{End}->[0].'<br/>';
		    $str .= ' Prefix: '.$arr[$j]->{Prefix}->[0].'<br/>';
		    $str .= ' Exact: '.$arr[$j]->{Exact}->[0].'<br/>';
		    $str .= ' Suffix: '.$arr[$j]->{Suffix}->[0].'<br/>';
		    $str .= '</li>';
		  }
		  $str .= '</ul>';
		}
		#$str .= @arr;
		$str .= '</li>';
	    }
	    $str .= '</ul>';
	$str .= '</li>';
    }
    $str .= '</ol>';

#    parseTemplate($ref);
    print $str;

#    print '<pre>'.Dumper($ref->{$id});
}




my $f = 'http://cirtec.ranepa.ru/analysis/43101.xml';

#print getContent1($f);


sub getContent1 
{
  my $text = get $_[0];
  my $parser = new MyXMLParser('content' => $text, 'encoding' => 'cp1251');
  my $hs = $parser->GetHashFromXmlFile();
  
  
  my $s = "";
  $s .= "<root>"; #.Dumper($hs); #->{bundle}->[0]->{ref}->[0]->{intextref}->[0]->{Suffix}->[0];
  foreach my $ref (@{$hs->{bundle}->[0]->{ref}}) {
    my $itm = $ref->{reference}->[0];
    $s .= '<reference num="'.$itm->{num}.'" handle="'.$ref->{found_in}.'" start="'.$itm->{start}.'" pubs="" intextref="" />';
    $s .='?' .Dumper($ref);
  }



 $s .= "</root>";
 return $s;
}


sub parseTemplate
{
  my $data = $_[0];
  my $tt = Template->new({
    INCLUDE_PATH => 'templates',
    INTERPOLATE  => 1,
    DEBUG => 0,
  })  || die "$Template::ERROR\n";
  
  my $vars = {
    root => $data,
    name     => 'Count Edward van Halen',
    debt     => '3 riffs and a solo',
    deadline => 'the next chorus',
  };

  $tt->process('main.html', $vars)
    || die $tt->error(), "\n";

}
=cut 
1;