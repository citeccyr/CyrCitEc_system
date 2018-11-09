package Cec::Paths;

our $dirs;
#$dirs->{'home'}=$ENV{'HOME'};
$dirs->{'home'}='/home/cec';
$dirs->{'perl'}=$dirs->{'home'}.'/perl';
$dirs->{'etc'}=$dirs->{'home'}.'/etc';
$dirs->{'var'}=$dirs->{'home'}.'/var';
$dirs->{'cgi'}=$dirs->{'home'}.'/cgi-bin';
$dirs->{'log'}=$dirs->{'var'}.'/log';
$dirs->{'bada'}=$dirs->{'home'}.'/var/opt/bada';
$dirs->{'stats'}=$dirs->{'home'}.'/var/stats';
$dirs->{'input'}=$dirs->{'home'}.'/var/opt/input';
$dirs->{'w2v'}=$dirs->{'home'}.'/var/opt/word2vec';
$dirs->{'series_stats'}=$dirs->{'home'}.'/var/opt/series_stats';
$dirs->{'warc'}=$dirs->{'home'}.'/lafka/warc';
$dirs->{'xslt'}=$dirs->{'home'}.'/xslt';
$dirs->{'sample'}=$dirs->{'home'}.'/sample';
$dirs->{'opt'}=$dirs->{'home'}.'/opt';
$dirs->{'peren'}=$dirs->{'opt'}.'/peren';
$dirs->{'db'}=$dirs->{'opt'}.'/db';
$dirs->{'work'}=$dirs->{'opt'}.'/work';
$dirs->{'www'}=$dirs->{'home'}.'/public_html/opt';
$dirs->{'hist'}=$dirs->{'home'}.'/public_html/stats';
$dirs->{'bundles'}=$dirs->{'home'}.'/public_html/opt/bundles';
$dirs->{'analysis'}=$dirs->{'home'}.'/public_html/opt/analysis';
$dirs->{'bundles_xml'}=$dirs->{'bundles'}.'/xml';
$dirs->{'bundles_pub'}=$dirs->{'bundles'}.'/pub';
$dirs->{'bundles_cit'}=$dirs->{'bundles'}.'/cit';
$dirs->{'bundles_dis'}=$dirs->{'bundles'}.'/dis';
$dirs->{'bundles_cro'}=$dirs->{'bundles'}.'/cro';
$dirs->{'to_learn'}=$dirs->{'www'}.'/opt/to_learn';
$dirs->{'cache'}=$dirs->{'opt'}.'/cache';
$dirs->{'python'}=$dirs->{'home'}.'/python';
$dirs->{'work'}=$dirs->{'opt'}.'/work';
$dirs->{'test'}=$dirs->{'work'}.'/test';
$dirs->{'refix'}=$dirs->{'home'}.'/opt/refidx';
$dirs->{'train'}=$dirs->{'work'}.'/train';
$dirs->{'git'}=$dirs->{'opt'}.'/git';
$dirs->{'rep'}=$dirs->{'home'}.'/git';
$dirs->{'doc'}=$dirs->{'home'}.'/doc';
$dirs->{'index'}=$dirs->{'opt'}.'/index';
$dirs->{'stats_web'}=$dirs->{'www'}.'/stats';
$dirs->{'wv'}=$dirs->{'git'}.'/webvectors';
$dirs->{'report'}=$dirs->{'www'}.'/stats';
$dirs->{'www_w2v'}=$dirs->{'bundles'}.'/Word2Vec';
$dirs->{'analysis_xml'}=$dirs->{'analysis'}.'/xml';
$dirs->{'analysis_pub'}=$dirs->{'analysis'}.'/pub';
$dirs->{'analysis_cit'}=$dirs->{'analysis'}.'/cit';
$dirs->{'analysis_dis'}=$dirs->{'analysis'}.'/dis';
$dirs->{'analysis_cro'}=$dirs->{'analysis'}.'/cro';

our $files;
$files->{'r_atyd2n'}=$dirs->{'refix'}.'/r_atyd2n.db';
$files->{'newphase_vic_cgi'}=$dirs->{'perl'}.'/newphase.vic.cgi';
$files->{'newphase_cgi'}=$dirs->{'cgi'}.'/newphase.cgi';
$files->{'r_list'}=$dirs->{'refix'}.'/r_list.stor';
$files->{'r_id2n'}=$dirs->{'refix'}.'/r_id2n.db';
$files->{'stats_output'}=$dirs->{'www'}.'/'.'stats.html';
$files->{'bada_sum'}=$dirs->{'cache'}.'bada_sum.json';
$files->{'wv_daemon'}=$dirs->{'wv'}.'/word2vec_server.py';
$files->{'wv_log'}=$dirs->{'log'}.'/word2vec_server.log';
$files->{'wv_err'}=$dirs->{'log'}.'/word2vec_server.err';
$files->{'handle_db'}=$dirs->{'db'}.'/panu.db';
$files->{'handle_dump'}=$dirs->{'opt'}.'/cyrcitec/handle.dump';
$files->{'dis_summary'}=$dirs->{'opt'}.'/prl/summary.json';
$files->{'xcont_json'}=$dirs->{'www'}.'/xcont.json';
$files->{'bundex_json'}=$dirs->{'www'}.'/bundex.json';
$files->{'spadis_json'}=$dirs->{'www'}.'/bundles/spadist/summary.json';
$files->{'crorf_json'}=$dirs->{'www'}.'/crorf.json';
$files->{'futlis'}=$dirs->{'cache'}.'/spz_to_lafka.json';
$files->{'recitex_script'}=$dirs->{'perl'}.'/recitex.pl';
$files->{'apply_recitex_script'}=$dirs->{'perl'}.'/apply_recitex';
$files->{'apply_recika_script'}=$dirs->{'perl'}.'/gather_recika';
$files->{'junk'}=$dirs->{'cache'}.'/junk.json';
$files->{'table_results'}=$dirs->{'cache'}.'/table_results.json';
$files->{'test_docs_good'}=$dirs->{'cache'}.'/test_docs_good';
$files->{'test_docs_bad'}=$dirs->{'cache'}.'/test_docs_bad';
$files->{'orig_cache'}=$dirs->{'cache'}.'/orig_sample_names.json';
$files->{'w2v_bin'}=$dirs->{'git'}."/word2vec/dav/word2vec/bin/word2vec";
$files->{'sph_in'}=$dirs->{'opt'}.'/cyrcitec/SPH.in';
$files->{'raw_fixes'}=$dirs->{'w2v'}.'/fixes.raw.txt';
$files->{'stem_fixes'}=$dirs->{'w2v'}.'/fixes.stem.txt';

1;
