#!/usr/bin/python3.7

#import datetime
#import time
#import os
#import os.path
#import stat
#import re
#from io import StringIO, BytesIO
#import urllib.request
#from pathlib import Path
#import lxml.etree as etree
#import json

## local imports 
import paths

import re
#import subprocess

from common import rsync

re_empty = re.compile("^\\s*$")
re_empty = re.compile("^\\s*$")

dirs = paths.dirs
files = paths.files
urls = paths.urls

rsync(urls['toc'], files['toc'])

