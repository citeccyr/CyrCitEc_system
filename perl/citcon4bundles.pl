#!/usr/bin/perl

use strict;
use POSIX;
use Getopt::Std;
use lib './Modules';
use MyXMLParser;
use LWP::Simple;
use Data::Dumper;
use Cyrcitec;

$| = 1; #flush output
my $trace = 1;							# output some trace info during parsing
my $dir = '/home/cec/public_html/opt/bundles/xml';  		# dir for parsing
my $out_file = 'citcon4bundles.txt';
my $FH;

my %o;
getopts('o:d:',\%o);
## -c directory with configs
## -o out json file
if($o{'d'}) { $dir = $o{'d'}; }
if($o{'o'}) { $out_file = $o{'o'}; }

my $count = 0;
main();


# ------------------------------------------------------------------------------------------------------


sub main
{
    my $res;
    my $nl = "\n";
    if($trace) { print 'start at '. strftime("%H:%M:%S", localtime(time))."\n"; } #%Y-%m-%d
    my @matches = $dir ? getCodesListOnDir($dir) : getCodesList();
    my $cnt = @matches;
    if($trace) { print 'Count: ' . $cnt.$nl; } 

    open FH, '>'.$out_file;
    for(my $i = 0; $i < @matches; $i++) {
	my $code = $matches[$i];
	my $idx = $i + 1;
	print $idx.' ' if $trace;
	SaveTxtLine($code);
    }
    close FH;

    if($trace) { print $nl.'end at '.strftime("%H:%M:%S\n", localtime(time)).$nl; }
    return $res;
}

sub SaveTxtLine
{
    my $code = $_[0];
    my $file = $dir.'/'.$code.'.xml';
    my $h = Cyrcitec::GetHashByFilePath($file);
    foreach my $k (keys %$h) {
	foreach my $hn (keys %{$h->{$k}->{pubs}}) {
	    my $exists;
	    my $num = $h->{$k}->{pubs}->{$hn}->{num};
	    #my $start = $h->{$k}->{pubs}->{$hn}->{start};
#	    print Dumper($h->{$k}->{pubs}->{$hn}); exit;
	    my @arr = @{$h->{$k}->{pubs}->{$hn}->{intextref}};
	    for(my $i = 0; $i < @arr; $i++) {
#		print Dumper(@arr);exit;
		if($arr[$i]) {
		    for(my $j = 0; $j < @{$arr[$i]}; $j++) {
			my $start = $arr[$i][$j]->{Start}->[0];
			if(!$exists->{$num.' '.$start}) {
			    $exists->{$num.' '.$start} = 1;
			    my $prefix = $arr[$i][$j]->{Prefix}->[0]; $prefix =~ s/\r//mgi; $prefix =~ s/ \n/ /mgi; $prefix =~ s/\n / /mgi; $prefix =~ s/\n/ /mgi; $prefix =~ s/[ \t]+/ /mgi; 
			    my $suffix = $arr[$i][$j]->{Suffix}->[0]; $suffix =~ s/\r//mgi; $suffix =~ s/ \n/ /mgi; $suffix =~ s/\n / /mgi; $suffix =~ s/\n/ /mgi; $suffix =~ s/[ \t]+/ /mgi; 
			    print FH $code.' '.$hn.' ' .$num.' '.$start .' '. $prefix.' '.$suffix."\n";
			}
		    }
		}
	    }
	}
    }
#print Dumper($h); exit;
}


sub getCodesList
{
    my $url = "http://cirtec.ranepa.ru/analysis/xml/";
    my $content = get $url;
    my @matches = $content =~ /<a href="[^\.]+.xml">([^\.]+).xml<\/a>/g;
    #print "??".$matches[0];
    return @matches;
}

sub getCodesListOnDir
{
    my $dir = $_[0];
    my @matches;
    my $cnt = 0;
    opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
    while (readdir $dh) {
	my $d = $_;
	if($d =~ /([^\.]+)\.xml/ && ($cnt < $count || $count == 0)) { $cnt++; push @matches, $1; }
    }
    closedir $dh;
#@matches = ('ro6x8q'); # 'NCm2rp');
    return @matches;
}
