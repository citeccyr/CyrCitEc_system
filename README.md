## Summary of scripts.

The best way to find out what is running here is to run

> crontab -l

This will list what is actually being performed.

* ~/bin/get_vicworks gets in input data from socionet.

* ~/perl/spz_to_lafka produces warc files with saved payloads from futlis.
  It takes a number of downloads to perform as an argument.

The following are performed in ~/bin/daily_update

* ~/perl/deal_with_warcs_peren produces pdf files into the peren
  directory. The peren structure has one directory per paper. This
  script generates the json files in these directories.

* ~/perl/apply_recitex does just what it says, it applies recitex to the
  pdf files that we have in peren.

* ~/perl/gather_recika produces the summary.xml files that that combine
  the recitex.xml files with provenance comming from the lafka and
  peren.

The following is run by ~/bin/get_vicworks

* ~/perl/get_bada produces lists of added and change Socionet data files
  in ~/var/opt/bada. This is not used, but could be starting step
  towards more efficient incremental processing.

----------------------------------------------------------------
