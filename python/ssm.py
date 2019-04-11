#!/usr/bin/python3.7

import datetime
import time
import os
import os.path
import stat
#import re
#from io import StringIO, BytesIO
import urllib.request
from pathlib import Path
import lxml.etree as etree

## local imports 

import paths

import json

dirs = paths.dirs
files = paths.files

group_name = 'Sinelnikov-Murylev'
tmp_fufi = '/tmp/ssm.xml'
ssm_url = 'http://msk4.socionet.ru/fs/lsearch.cgi?h=repec:per:pers:psi499'
ssm_base = 'http://no-xml.socionet.ru/~cyrcitec/groups/' + group_name + '/'
ssm_url += '&cnt=c_out&relation=citation&l=en'
ssm_files = ['citing_papers.txt', 'linked_papers.txt', 'perperspsi499.xml']
ssm_dir = dirs['group_out'] + '/' + group_name
#
spz_to_lafka_fufi = files['futli']
#pdf_warcs_fufi = dirs['home'] + '/var/opt/series_stats/pdf_warcs.json'
pdf_warcs_fufi = files['pdf_stats']
#json_fufi = dirs['home'] + '/var/opt/series_stats/json.json'
json_fufi = files['json_stats']
#series_stats_dir = dirs['home'] + '/var/opt/series_stats'
series_stats_dir = dirs['series_stats']
html_dir = dirs['group_out']
group_html_dir = html_dir + '/' + group_name
group_html_cover_fufi = group_html_dir + '/index.html'
#
xslt_dir = dirs['xslt']
group_index_xslt_fufi = xslt_dir + '/group_index.xslt.xml'

## count declared here to make them global
c = {} 

# mtime --> mage
def mage(pathname):
    return time.time() - os.stat(pathname)[stat.ST_MTIME]


def get_url(url , out_fufi):
    out_path = Path(out_fufi)
    if(out_path.is_file() and (mage(tmp_fufi) < 24 * 3600)):
        return
    with urllib.request.urlopen(url) as response:
        response_string = response.read().decode('utf-8')
        text_file = open(out_fufi, "w")
        text_file.write(response_string)
        text_file.close()


def id_to_bibfile(handle):    
    if(handle.startswith('repec')):
        handle = handle[6:]
    data_file = handle.replace(':' , '/', 1)
    dir_part = data_file.partition(':')[0]
    file_part = dir_part.replace('/', '', 1)
    file_part = file_part.replace(':', '', 1)
    local_id = handle.split(':')[2]
    file = dirs['input'] + '/' + dir_part + '/' + file_part + local_id + '.xml'
    if(os.path.isfile(file)):
        return file
    print(file)
    return ""


def id_to_futli(handle):
    if(handle in spz_to_lafka):
        return 1
    return 0


def id_to_pdf_warcs(handle):
    if(handle in has_pdf_warcs):
        return 1
    return 0


def id_to_has_json(handle):
    if(handle in has_json):
        return 1
    return 0


def id_to_series_stats_file(handle):
    #print(str(handle).split(':'))
    series = ':'.join(handle.split(':')[0:3])
    fufi = series_stats_dir + '/' + series.lower() + '.xml'
    if(not os.path.isfile(fufi)):
        print("I can not find " + fufi)
        return None
    print("I found " + fufi)
    tree = etree.parse(fufi)
    doc_eles = tree.xpath("//doc[@handle='" + handle + "']")
    if(not len(doc_eles)):
        print("I don't have an element for " + handle)    
        print(etree.tostring(tree).decode('utf-8'))
        return None
    print("I HAVE  an element for " + handle)    
    return doc_eles[0]
    #print(doc_ele)
    

def id_to_warcfile(handle):
    bana = handle
    bana = bana.replace('repec:', 'RePEc/')
    bana = bana.replace(':' , '/', 2)
    bana = bana+'.warc'
    fufi = dirs['warc'] + '/' + bana
    if(os.path.isfile(fufi)):
        #print('warc is there')
        return fufi
    #print("I don't see "+fufi)
    return ""


def build_xml(series):
    series_ele = etree.Element('series')
    series_ele.set('id', series)
    records_ele = etree.Element('records')
    records_ele.text = str(c[series]['count_records'])
    series_ele.append(records_ele)
    has_futli_ele = etree.Element('has_futli')
    has_futli_ele.text = str(c[series]['count_futlis'])
    series_ele.append(has_futli_ele)
    warcs_ele = etree.Element('warcs')
    warcs_ele.text = str(c[series]['count_warcs'])
    series_ele.append(warcs_ele)
    pdf_warcs_ele = etree.Element('pdf_warcs')
    pdf_warcs_ele.text = str(c[series]['count_futlis'])
    series_ele.append(pdf_warcs_ele)
    has_json_ele = etree.Element('json')
    has_json_ele.text = str(c[series]['count_futlis'])
    series_ele.append(has_json_ele)
    refs_ele = etree.Element('refs')
    refs_ele.text = str(c[series]['count_refs'])
    series_ele.append(refs_ele)
    mits_ele = etree.Element('mits')
    mits_ele.text = str(c[series]['count_mits'])
    series_ele.append(mits_ele)
    ints_ele = etree.Element('ints')
    ints_ele.text = str(c[series]['count_ints'])
    series_ele.append(ints_ele)
    cons_ele = etree.Element('cons')
    cons_ele.text = str(c[series]['count_cons'])
    series_ele.append(cons_ele)
    cits_ele = etree.Element('cits')
    cits_ele.text = str(c[series]['count_cits'])
    series_ele.append(cits_ele)
    cref_ele = etree.Element('cref')
    cref_ele.text = str(c[series]['stats_a'])
    series_ele.append(cref_ele)
    cint_ele = etree.Element('cint')
    cint_ele.text = str(c[series]['stats_b'])
    series_ele.append(cint_ele)
    ccon_ele = etree.Element('ccon')
    ccon_ele.text = str(c[series]['stats_c'])
    series_ele.append(ccon_ele)
    ccit_ele = etree.Element('ccit')
    ccit_ele.text = str(c[series]['stats_d'])
    series_ele.append(ccit_ele)
    cmit_ele = etree.Element('cmit')
    cmit_ele.text = str(c[series]['stats_e'])
    series_ele.append(cmit_ele)
    root_ele.append(series_ele)
    print(etree.tostring(series_ele, pretty_print=True).decode('utf-8'))


def add_paper_to_series(paper , series):
    if(series not in c):
        c[series] = {}       
    if('count_records' not in c[series]):
        c[series]['count_records'] = 0
    if('count_warcs' not in c[series]):
        c[series]['count_warcs'] = 0
    if('count_pdf_warcs' not in c[series]):
        c[series]['count_pdf_warcs'] = 0
    if('count_futlis' not in c[series]):
        c[series]['count_futlis'] = 0
    if('count_has_json' not in c[series]):
        c[series]['count_has_json'] = 0
    if('stats_a' not in c[series]):
        c[series]['stats_a'] = 0
    if('stats_b' not in c[series]):
        c[series]['stats_b'] = 0
    if('stats_c' not in c[series]):
        c[series]['stats_c'] = 0
    if('stats_d' not in c[series]):
        c[series]['stats_d'] = 0
    if('stats_e' not in c[series]):
        c[series]['stats_e'] = 0
    if('count_return_ref' not in c[series]):
        c[series]['count_return_ref'] = 0
    if('count_ints' not in c[series]):
        c[series]['count_ints'] = 0
    if('count_cons' not in c[series]):
        c[series]['count_cons'] = 0
    if('count_cits' not in c[series]):
        c[series]['count_cits'] = 0
    if('count_mits' not in c[series]):
        c[series]['count_mits'] = 0
    if('count_refs' not in c[series]):
        c[series]['count_refs'] = 0
    bibfile = id_to_bibfile(paper)
    if(bibfile):
        c[series]['count_records'] = c[series]['count_records'] + 1
    warcfile = id_to_warcfile(paper)
    if(warcfile):
        c[series]['count_warcs'] = c[series]['count_warcs'] + 1
    futli = id_to_futli(paper)
    if(futli):
        c[series]['count_futlis'] = c[series]['count_futlis'] + 1
    pdf_warcs = id_to_pdf_warcs(paper)
    if(pdf_warcs):
        c[series]['count_pdf_warcs'] = c[series]['count_pdf_warcs'] + 1
    json = id_to_pdf_warcs(paper)
    if(json):
        c[series]['count_has_json'] = c[series]['count_has_json'] + 1
    doc_ele = id_to_series_stats_file(paper)
    ## the rest is all in the doc_ele! 
    if(doc_ele is None):
        quit
        return
    stats = doc_ele.attrib
    print(stats['stats_a'])
    if(stats['stats_a']):
        c[series]['stats_a'] += int(stats['stats_a'])
        c[series]['count_refs'] = c[series]['count_refs'] + 1
    if(stats['stats_b']):
        c[series]['stats_b'] += int(stats['stats_b'])
        c[series]['count_ints'] = c[series]['count_ints'] + 1
    if(stats['stats_c']):
        c[series]['stats_c'] +=  int(stats['stats_c'])
        c[series]['count_cons'] = c[series]['count_cons'] + 1
    if(stats['stats_d']):
        c[series]['stats_d'] = int(stats['stats_d'])
        c[series]['count_cits'] = c[series]['count_cits'] + 1
    if(stats['stats_e']):
        c[series]['stats_e'] = int(stats['stats_e'])
        c[series]['count_mits'] = c[series]['count_mits'] + 1


group_index_xslt_string = ''
with open(group_index_xslt_fufi, 'r') as group_index_xslt_file:
    group_index_xslt_string = group_index_xslt_file.read()

group_index_sheet = etree.XSLT(etree.parse(group_index_xslt_fufi))

with open(spz_to_lafka_fufi) as spz_to_lafka_file:
    spz_to_lafka = json.load(spz_to_lafka_file)

with open(pdf_warcs_fufi) as pdf_warcs_file:
    has_pdf_warcs = json.load(pdf_warcs_file)

with open(json_fufi) as json_file:
    has_json = json.load(json_file)

today = datetime.datetime.today().strftime('%Y-%m-%d')

for fina in ssm_files:
    to_get_url = ssm_base + '/' + fina
    target_file = ssm_dir + '/' + fina
    print(to_get_url + ' --> ' + target_file)
    get_url(to_get_url , target_file)

citing_papers_fufi = ssm_dir + '/' + 'citing-papers.txt'
with open(citing_papers_fufi) as f:
    citing_papers_list = f.read().splitlines()

citing_papers_fufi = ssm_dir + '/' + 'citing-papers.txt'
with open(citing_papers_fufi) as f:
    citing_papers_list = f.read().splitlines()

linked_papers_fufi = ssm_dir + '/' + 'linked_papers.txt'
with open(linked_papers_fufi) as f:
    linked_papers_list = f.read().splitlines()

for paper in citing_papers_list:
    add_paper_to_series(paper, 'citing_papers')    
for paper in linked_papers_list:
    add_paper_to_series(paper, 'linked_papers')


## build XML
root_ele = etree.Element('table')
root_ele.set('version', '1.0')
root_ele.set('date', today)
root_ele.set('group', 'yes')
build_xml('citing_papers')
build_xml('linked_papers')

print(etree.tostring(root_ele, pretty_print=True).decode('utf-8'))
group_html = group_index_sheet(root_ele)
print(str(group_html))
group_html.write_output(group_html_cover_fufi)


