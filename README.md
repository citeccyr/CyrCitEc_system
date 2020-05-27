## Summary of scripts

The best way to find out what is running here is to run

> crontab -l

This will list what is actually being performed.

* ~/bin/get_vicworks gets in input data from socionet.

* oai_converter contains code written by Victor M. Lyapunov
  that directly downloads and converts from an oai data provider. 

* ~/perl/spz_to_lafka produces warc files with saved payloads from futlis.
  It takes a number of downloads to perform as an argument.

*  ~/perl/save_stats -i
  saves the stats part of the web site

The following are performed in ~/bin/daily_update

* ~/perl/deal_with_warcs_peren produces pdf files into the peren directory. The
  PDF conversion uses PDF stream CLI, as listed in the related repositories. The
  peren structure has one directory per paper. This script generates the json
  files in these directories.

* ~/perl/apply_recitex does just what it says, it applies recitex to the
  pdf files that we have in peren.

* ~/perl/gather_recika produces the summary.xml files that that combine
  the recitex.xml files with provenance comming from the lafka and
  peren.

* ~/perl/cover_stats produces the cover page of the statistics

* ~/perl/stats produces other parts of the statistics

* ~/perl/bundles is the main script for the analysis section



## Related repositories

The following repositories contain work that was written as part of Cirtec.

* [PDF stream CLI](https://github.com/citeccyr/pdf-stream-cli)

* [Topic modeling for the analysis](https://github.com/bakarov/cirtec)

* [N-grams and Clustering](https://github.com/gipertech/cirtec)

* [Database](https://github.com/tonal/cirtec_db)

* [Logical labeling PFD documents](https://github.com/citations-ai/linelabeler) 

## [Cirtec Outputs](http://cirtec.ranepa.ru/)

The Cirtec project is funded by [RANEPA](https://www.ranepa.ru/eng/).


----------------------------------------------------------------
