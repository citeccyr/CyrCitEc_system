#!/usr/bin/python3.7

# from random import shuffle
import re
import subprocess
import paths
# import glob
import os.path

re_empty = re.compile("^\\s*$")
re_toc_line = re.compile("^(\\S+) (\\S+)$")
re_comment = re.compile("^\\s*#")
#re_prefix = re.compile("^[^:]+:([^:]+):")
#re_prefix_archive = re.compile("^([^:]+:[^:]+):")
re_pasi = re.compile("^([^:]+):([^:]+):([^:]+):(.*)$")

dirs = paths.dirs
files = paths.files
urls = paths.urls
hosts = paths.hosts


def rsync(url, fufi, do_test=False):
    if(do_test):
        print(url + ' --> ' + fufi)
        subprocess.run(['rsync', '-vna', url, fufi])
    else:
        print('rsync -va ' + url + ' ' + fufi)
        subprocess.run(['rsync', '-qa', url, fufi])


## get groups
rsync(urls['groups'], dirs['groups'])

## get the downloader
rsync(urls['group_bib_script'], files['tmp_group_download_script'])

## run the downloaded
subprocess.run([files['tmp_group_download_script'], dirs['tmp_group_bibdata'],
                '0'])

## install the bib data
for sub_dir in ('RePEc', 'spz'):
    start_dir = dirs['tmp_group_bibdata'] + '/' + sub_dir + '/'
    rsync(start_dir, dirs['bib_input'])

## delete the futlis file to force a rejeceration
if(os.path.isfile(files['futli'])):
    os.remove(files['futli'])
#print(dirs['perl'])
quit()


        
################################################################################
# rsync(urls['toc'], files['toc'])

# 
# quit()
# 
# ## get the table of contents
# with open(files['toc']) as rsync_toc_file :
#     toc_lines = rsync_toc_file.read().splitlines()
# 
# for toc_line in toc_lines:
#     #toc_string = toc_line.decode('utf-8')
#     if(re_empty.search(toc_line)):
#         continue
#     if(re_comment.search(toc_line)):
#         continue
#     #print(toc_line)
#     re_toc_line_matched = re_toc_line.search(toc_line)
#     if(not re_toc_line_matched):
#         print("I can not match " + toc_line)
#     formating = re_toc_line_matched.group(1)
#     archive = re_toc_line_matched.group(2)
#     ## we mix archives from the spz and repec by jsut
#     ## takenig the part after the -, if there is a dash
#     local_dir = archive
#     if('-' in archive):
#         #archive_matched = re_before_dash.search(archive)        
#         local_dir = archive.split('-')[1]
#     target = dirs['input'] + '/' + archive
#     #print('archive ' + archive)
#     #print('local_dir ' + local_dir)
#     url = 'rsync://' + hosts['vicsync'] + '/' + archive + '/'
#     local_dir = dirs['input'] + '/' + local_dir
#     #print(url + ' --> ' + local_dir)
#     rsync(url, local_dir)
#     
# 
# quit()
# 
#     
# group_dirs = glob.glob(dirs['groups'] + '/*')
# #print(group_dirs)
# files = []
# get_handles = {}
# for group_dir in group_dirs:
#     print(group_dir + '/*.txt')
#     for txt_fufi in glob.glob(group_dir + '/*.txt'):
#         #print("I open " + txt_fufi)
#         files.append(txt_fufi)
#         with open(txt_fufi) as txt_file:
#             found_handles = txt_file.read().splitlines()
#             for found_handle in found_handles:
#                 found_handle = found_handle.lower()
#                 get_handles[found_handle] = 1
# 
# get_handles = list(get_handles.keys())
# print(type(get_handles))
# shuffle(get_handles)
# for handle in get_handles:
#     #prefix = re_prefix.search(handle).group(1)
#     #prefix_archive = re_prefix_archive.search(handle).group(1)
#     #print(handle + ' ' + archive + ' ' + prefix_archive)
#     pasi = re_pasi.search(handle)
#     if(not pasi):
#         print(handle + ' no match')
#         continue
#     prefix = pasi.group(1)
#     archive = pasi.group(2)
#     series = pasi.group(3)
#     item = pasi.group(4)
#     base_url = 'rsync://' + hosts['vicsync'] + '/' + archive + '/' + series
#     ## short form: rsync://1.old.socionet.ru/ARC/SERIES/code.xml
#     short_form = item + '.xml'
#     ## long form rsync://1.old.socionet.ru/ARC/SERIES/ARCSERIEScode.xml
#     long_form = archive + series + item + '.xml'
#     short_url = base_url + '/' + short_form 
#     long_url = base_url +  '/' + long_form
#     local_base = dirs['input'] + '/' + archive + '/' + series 
#     local_base_dir = os.path.dirname(local_base)
#     if(not os.path.isdir(local_base_dir)):
#         os.mkdir(local_base_dir)
#     short_local = local_base + short_form
#     if(os.path.isfile(short_local)):
#         print("I found " + short_local)
#         continue
#     long_local = local_base + long_form
#     if(os.path.isfile(long_local)):
#         print("I found " + long_local)
#         continue
#     print(long_url + ' --> ' + long_local)
#     rsync(long_url, long_local)
#     if(os.path.isfile(long_local)):
#         print("I found " + long_local)
#         continue
#     print(short_url + ' --> ' + short_local)
#     rsync(short_url, short_local)
#     

quit()


    
