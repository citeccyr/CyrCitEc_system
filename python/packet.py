#!/usr/bin/python3.7

import with_files
import with_groups
import paths


#series_types = with_groups.series_types
#dirs = paths.dirs
#files = paths.files
#urls = paths.urls
groups = with_groups.list()

handles_fufi = paths.files['bibfiles']

records = with_files.load(handles_fufi)

for group in groups:
    with_groups.build_packets(group, records) 
