package BundleConfig;


# USAGE:
# my %b = BundleConfig->new('en');
 

use strict;
use warnings;

use Cec::Paths;
use Sys::Hostname;

my $files=$Cec::Paths::files;
my $dirs=$Cec::Paths::dirs;

my $type = '';

sub _init
{
  my $self = shift;
  $type = shift;
}


# get specific setting for create bundles/groups
sub new
{
  my $self = shift;
  $type = shift; $type = '' if !$type;
  
  my %set;
  my $mydir = '/home/prl/opt/refidx';
	if($type eq 'ru' || $type eq 'en') 
	{
		$set{'conf'} = $type;
		
		$set{'base_dir'} = '/home/prl/www'; # create dirs under that
		$set{'bundles_dir'} = $set{'base_dir'}.'/bundles'; 
		$set{'bundles'} = $set{'bundles_dir'}.'/'.$type;
		
		$set{'r_list'} = $mydir.'/r_list.stor';
		$set{'shids'} = $mydir.'/r_shids.stor';
		$set{'r_atyd2n'} = $mydir.'/r_atyd2n.db';
		$set{'dis_summary'} = $mydir.'/summary.'.$type.'.json';
		
		$set{'series'} = $self->get_series($type, $mydir);
		
		$set{'bundles_xml'} = $set{'bundles'}.'/xml';
		$set{'bundles_cit'} = $set{'bundles'}.'/cit';
		$set{'bundles_pub'} = $set{'bundles'}.'/pub';
		$set{'bundles_cro'} = $set{'bundles'}.'/cro';
		$set{'bundles_dis'} = $set{'bundles'}.'/dis';
		$set{'www_w2v_json'} = $mydir.'/topic_output.'.$type.'.json';
		$set{'www_freq_json'} = $mydir.'/words_freqs.'.$type.'.json';
		$set{'www_w2v_grams_json'} = $mydir.'/grams.'.$type.'.json';
		$set{'exceptions'} = ['repec:bkr','repec:cfr','repec:eus','repec:hig','repec:mmb'];
	}
	elsif($type ne '') { #group
		$mydir = '/home/prl/opt/groups';
		$set{'conf'} = $type;

		$set{'base_dir'} = '/home/prl/www'; # create dirs under that
		$set{'bundles_dir'} = $set{'base_dir'}.'/groups';
		$set{'bundles'} = $set{'bundles_dir'}.'/'.$type;
		
		$set{'r_atyd2n'} = $mydir.'/'.$type.'/r_atyd2n.db';
		$set{'r_refs'} = $mydir.'/'.$type.'/r_refs.db';
		$set{'r_list'} = $mydir.'/'.$type.'/r_list.stor';
		$set{'dis_summary'} = $mydir.'/'.$type.'/summary.json';
		#	$set{'groups'} = $set{'base_dir'}.'/groups';
		
		$set{'bundles_xml'} = $set{'bundles'}.'/xml';
		$set{'bundles_cit'} = $set{'bundles'}.'/cit';
		$set{'bundles_pub'} = $set{'bundles'}.'/pub';
		$set{'bundles_cro'} = $set{'bundles'}.'/cro';
		$set{'bundles_dis'} = $set{'bundles'}.'/dis';
		
		$set{'www_w2v_json'} = $mydir.'/'.$type.'/topic_output.json';
		$set{'www_freq_json'} = $mydir.'/'.$type.'/words_freqs.json';
		$set{'www_w2v_grams_json'} = $mydir.'/'.$type.'/grams.json';
		
		$set{'xcont_json'} = $mydir.'/'.$type.'/xcont.json';
		$set{'crorf_json'} = $mydir.'/'.$type.'/crorf.json';  # should be global

	} else { 
		$set{'conf'} = '';
		$set{'r_list'} = $files->{'r_list'}; 
		$set{'shids'} = '';
		$set{'r_atyd2n'} = $files->{'r_atyd2n'};
		$set{'dis_summary'} = $files->{'dis_summary'};
		
		$set{'bundles'} = $dirs->{'bundles'};
		$set{'bundles_xml'} = $dirs->{'bundles_xml'};
		$set{'bundles_cit'} = $dirs->{'bundles_cit'};
		$set{'bundles_pub'} = $dirs->{'bundles_pub'};
		$set{'bundles_cro'} = $dirs->{'bundles_cro'};
		$set{'bundles_dis'} = $dirs->{'bundles_dis'};
		$set{'www_w2v_json'} = $dirs->{'www_w2v'}.'/topic_output.json';
		$set{'www_w2v_grams_json'} = $dirs->{'www_w2v'}.'/2-3-4-5-6_grams_v3.json';
		
		$set{'xcont_json'} = $files->{'xcont_json'};
		$set{'crorf_json'} = $files->{'crorf_json'};
		# groups $Cec::Paths::dirs->{'groups'}
	}
	
	$set{'hostname'} = hostname;
	if($set{'hostname'} eq 'olgil') { 
		$set{'self_url'}="http://cirtec.repec.org";
	} else { # evstu:
		$set{'self_url'}="http://cirtec.ranepa.ru";
	}
	
	
	return \%set;
  
}

sub get_series {
	my $self = shift;
	my $lang = shift; 
	my $dir = shift;
	my $file = $dir.'/A-list';
	
	my $login = getlogin() || '';
	my $data;
	my $series;
	
	if($login) {
		if($login eq 'prl') { 
			# get from local
			$data = `cat $file`;
		} else {
			# cec user take from socionet.ru (see langs_series.py)
			$data = `ssh cyrcitec\@socionet.ru cat A-list`;
		}
		
		my @lines = split(/\n/, $data);
		foreach my $line (@lines) {
			my @parts = split(/\s+/, $line);
			if( (scalar @parts == 2 && $lang eq 'en') || (scalar @parts == 3 && $lang ne 'en') )
				{ push @$series, $parts[0]; }
		}
	}
	return $series;
}

1;