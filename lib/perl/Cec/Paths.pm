package Cec::Paths;

our $dirs;
$dirs->{'home'}=$ENV{'HOME'};
$dirs->{'perl'}=$dirs->{'home'}.'/perl';
$dirs->{'bada'}=$dirs->{'home'}.'/var/opt/bada';
$dirs->{'input'}=$dirs->{'home'}.'/var/opt/input';
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
$dirs->{'work'}=$dirs->{'opt'}.'/work';
$dirs->{'test'}=$dirs->{'work'}.'/test';
$dirs->{'train'}=$dirs->{'work'}.'/train';

our $files;
$files->{'stats_output'}=$dirs->{'www'}.'/'.'stats.html';
$files->{'bada_sum'}=$dirs->{'cache'}.'bada_sum.json';
$files->{'handle_db'}=$dirs->{'db'}.'/panu.db';
$files->{'futlis'}=$dirs->{'cache'}.'/spz_to_lafka.json';
$files->{'recitex_script'}=$dirs->{'perl'}.'/recitex.pl';
$files->{'junk'}=$dirs->{'cache'}.'/junk.json';
$files->{'table_results'}=$dirs->{'cache'}.'/table_results.json';
$files->{'test_docs_good'}=$dirs->{'cache'}.'/test_docs_good';
$files->{'test_docs_bad'}=$dirs->{'cache'}.'/test_docs_bad';
$files->{'orig_cache'}=$dirs->{'cache'}.'/orig_sample_names.json';

1;
