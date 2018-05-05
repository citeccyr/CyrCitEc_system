package Cec::Paths;

our $dirs;
$dirs->{'home'}=$ENV{'HOME'};
$dirs->{'perl'}=$dirs->{'home'}.'/perl';
$dirs->{'etc'}=$dirs->{'home'}.'/etc';
$dirs->{'var'}=$dirs->{'home'}.'/var';
$dirs->{'log'}=$dirs->{'var'}.'/log';
$dirs->{'bada'}=$dirs->{'home'}.'/var/opt/bada';
$dirs->{'stats'}=$dirs->{'home'}.'/var/stats';
$dirs->{'input'}=$dirs->{'home'}.'/var/opt/input';
$dirs->{'w2v'}=$dirs->{'home'}.'/var/opt/word2vec';
$dirs->{'warc'}=$dirs->{'home'}.'/lafka/warc';
$dirs->{'xslt'}=$dirs->{'home'}.'/xslt';
$dirs->{'sample'}=$dirs->{'home'}.'/sample';
$dirs->{'opt'}=$dirs->{'home'}.'/opt';
$dirs->{'peren'}=$dirs->{'opt'}.'/peren';
$dirs->{'db'}=$dirs->{'opt'}.'/db';
$dirs->{'work'}=$dirs->{'opt'}.'/work';
$dirs->{'www'}=$dirs->{'home'}.'/public_html/opt';
$dirs->{'to_learn'}=$dirs->{'www'}.'/opt/to_learn';
$dirs->{'cache'}=$dirs->{'opt'}.'/cache';
$dirs->{'python'}=$dirs->{'home'}.'/python';
$dirs->{'work'}=$dirs->{'opt'}.'/work';
$dirs->{'test'}=$dirs->{'work'}.'/test';
$dirs->{'train'}=$dirs->{'work'}.'/train';
$dirs->{'git'}=$dirs->{'opt'}.'/git';
$dirs->{'index'}=$dirs->{'opt'}.'/index';
$dirs->{'wv'}=$dirs->{'git'}.'/webvectors';

our $files;
$files->{'stats_output'}=$dirs->{'www'}.'/'.'stats.html';
$files->{'bada_sum'}=$dirs->{'cache'}.'bada_sum.json';
$files->{'wv_daemon'}=$dirs->{'wv'}.'/word2vec_server.py';
$files->{'wv_log'}=$dirs->{'log'}.'/word2vec_server.log';
$files->{'wv_err'}=$dirs->{'log'}.'/word2vec_server.err';
$files->{'handle_db'}=$dirs->{'db'}.'/panu.db';
$files->{'handle_dump'}=$dirs->{'opt'}.'/cyrcitec/handle.dump';
$files->{'futlis'}=$dirs->{'cache'}.'/spz_to_lafka.json';
$files->{'recitex_script'}=$dirs->{'perl'}.'/recitex.pl';
$files->{'apply_recitex_script'}=$dirs->{'perl'}.'/apply_recitex';
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
