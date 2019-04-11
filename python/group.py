#!/usr/bin/python3.7

import datetime
import glob
import os
import os.path
#import stat
import re
import json
import lxml.etree as etree

## local imports 
import paths
import with_files
import cec

re_empty = re.compile("^\\s*$")

## dealing with meanining
char2count = {}
char2count['a'] = 'refs'
char2count['b'] = 'ints'
char2count['c'] = 'cons'
char2count['d'] = 'cits'
char2count['e'] = 'mits'
char2count['f'] = 'reci'

char2sum = {}
char2sum['a'] = 'cref'
char2sum['b'] = 'cint'
char2sum['c'] = 'ccon'
char2sum['d'] = 'ccit'
char2sum['e'] = 'cmit'

dirs = paths.dirs
files = paths.files
urls = paths.urls

## get groups
groups = []
## they are the directory names
for dir in glob.glob(dirs['groups'] + '/*'):
    groups.append(os.path.basename(dir))

series_types = ('citing_papers', 'cited_papers', 'linked_papers')
#rec_types = ('items', 'records', 'futlis', 'warcs', 'pdf_warcs', 'jsons')
rec_types = ('records', 'futlis', 'warcs', 'pdf_warcs', 'jsons', 'recika')
## items added later

## global container of all the data, within groups or outside
data = {}

## stats files are produced by the perl system
for rec_type in rec_types:
    data[rec_type] = {}
    stats_type = rec_type + '_stats'
    stats_fufi = files[stats_type]
    if(not os.path.isfile(stats_fufi)):
        print("I don't see stats_fufi " + stats_fufi)
        quit()
    with open(stats_fufi) as stats_file:
        data_input = json.load(stats_file)
    print(type(data_input))
    for item in data_input:
        data[rec_type][item] = data_input[item]


## initalize the holder
def init_holder():
    global holder
    holder = {}
    for series in series_types:
        holder[series] = {}
        for rec_type in rec_types:
            holder[series][rec_type] = {}
        holder[series]['items'] = {}


series_stats_dir = dirs['series_stats']
html_dir = dirs['group_out']

## count declared here to make them global
c = {}

## to contain the stats for any series
series_ele = etree.Element('series')

## load stylesheets
xslt_dir = dirs['xslt']
group_index_xslt_fufi = xslt_dir + '/stats_cover.xslt.xml'
group_index_sheet = etree.XSLT(etree.parse(group_index_xslt_fufi))
groups_index_xslt_fufi = xslt_dir + '/groups_index.xslt.xml'
groups_index_sheet = etree.XSLT(etree.parse(groups_index_xslt_fufi))
stats_series_xslt_fufi = xslt_dir + '/stats_series.xslt.xml'
stats_series_sheet = etree.XSLT(etree.parse(stats_series_xslt_fufi))
stats_missing_xslt_fufi = xslt_dir + '/stats_missing.xslt.xml'
stats_missing_sheet = etree.XSLT(etree.parse(stats_missing_xslt_fufi))
#itemsrecords_xslt_fufi = xslt_dir + '/stats_group_itemsrecords.xslt.xml'
#itemsrecords_sheet = etree.XSLT(etree.parse(itemsrecords_xslt_fufi))

today = datetime.datetime.today().strftime('%Y-%m-%d')
pretty_today = datetime.datetime.today().strftime(u'%Y\u2012%m\u2012%d')

## a state whether a rec_type is missing
has_missing = {}


def remove_values_from_dict(in_dict, value):
    out_dict = {}
    for papid in in_dict:
        if(in_dict[papid] == value):
            continue
        out_dict[papid] = in_dict[papid]
    #print('out_dict')
    #print(out_dict)
    return out_dict


## takes the difference between two holder
def diff_between_holder_parts(big, small):
    big_holder = big
    big_values = remove_values_from_dict(big_holder, -1)
    #print('small_holder')
    #print(small)
    small_holder = small
    small_values = remove_values_from_dict(small_holder, -1)
    diff = list(set(big_values) - set(small_values))
    return diff


def paper_to_holder(papid, series, rec_type):
    if(papid in data[rec_type]):
        holder[series][rec_type][papid] = 1
        return 1
    holder[series][rec_type][papid] = -1
    return 0

       
def id_to_series_stats_ele(papid):
    #print(str(papid).split(':'))
    series = ':'.join(papid.split(':')[0:3])
    fufi = series_stats_dir + '/' + series.lower() + '.xml'
    if(not os.path.isfile(fufi)):
        print("I can not find " + fufi)
        return None
    print("I found " + fufi)
    tree = etree.parse(fufi)
    doc_eles = tree.xpath("//doc[@handle='" + papid + "']")
    if(not len(doc_eles)):
        print("I don't have an element for " + papid)    
        print(etree.tostring(tree).decode('utf-8'))
        return None
    print("I HAVE  an element for " + papid)    
    return doc_eles[0]
    #print(doc_ele)

    
def build_xml(series, holder):
    series_ele = etree.Element('series')
    series_ele.set('series', series)
    ## references in the xslt
    series_ele.set('id', series)
    items_ele = etree.Element('items')
    items_ele.text = str(len(holder['items']))
    series_ele.append(items_ele)
    records_ele = etree.Element('records')
    if(has_missing['records']):
        records_ele.set('missing', str(len(holder['records'])))
    #print("| holder of records of " + series + " is ")
    #print(holder['records'])    
    present_records = remove_values_from_dict(holder['records'], -1)
    count_present_records = str(len(present_records))
    records_ele.text = str(len(present_records))
    print("I count " + count_present_records + " present record for " + series)
    series_ele.append(records_ele)                      
    has_futli_ele = etree.Element('has_futli')
    if(has_missing['futlis']):
        has_futli_ele.set('missing', str(len(holder['futlis'])))
    has_futli_ele.text = str(c[series]['count_futlis'])
    series_ele.append(has_futli_ele)
    warcs_ele = etree.Element('warcs')
    if(has_missing['warcs']):
        warcs_ele.set('missing', str(len(holder['warcs'])))
    warcs_ele.text = str(c[series]['count_warcs'])
    series_ele.append(warcs_ele)
    pdf_warcs_ele = etree.Element('pdf_warcs')
    if(has_missing['pdf_warcs']):
        pdf_warcs_ele.set('missing', str(len(holder['pdf_warcs'])))
    pdf_warcs_ele.text = str(c[series]['count_pdf_warcs'])
    series_ele.append(pdf_warcs_ele)
    json_ele = etree.Element('json')
    if(has_missing['jsons']):
        json_ele.set('missing', str(len(holder['jsons'])))
    json_ele.text = str(c[series]['count_jsons'])
    series_ele.append(json_ele)
    recika_ele = etree.Element('recika')
    if(has_missing['recika']):
        print(series + "has_missing recica")
        print(has_missing['recika'])
        print(len(holder['jsons']))
        print(len(holder['recika']))
        recika_ele.set('missing', str(len(holder['recika'])))
    else:
        print(series + " has no missing recika")        
    recika_ele.text = str(c[series]['count_recika'])
    series_ele.append(recika_ele)
    for char in char2count:
        ele = etree.Element(char2count[char])
        count_char = 'count_' + char2count[char]
        ele.text = str(c[series][count_char])
        series_ele.append(ele)
    for char in char2sum:
        ele = etree.Element(char2sum[char])
        ele.text = str(c[series]['stats_' + char])
        series_ele.append(ele)
    root_ele.append(series_ele)
    print(etree.tostring(series_ele, pretty_print=True).decode('utf-8'))


def add_paper_to_series(papid, series, series_ele):
    papid = papid.lower()
    if(series not in c):
        c[series] = {}       
    ## initialize
    for rec_type in rec_types:
        counter = 'count_' + rec_type
        if(counter not in c[series]): 
            c[series][counter] = 0
    for char in char2sum:
        stats_char = 'stats_' + char
        if(stats_char not in c[series]):
            c[series][stats_char] = 0
    ## this is the start of a strange body
    if('count_return_ref' not in c[series]):
        c[series]['count_return_ref'] = 0
    for char in char2count:
        count_char = 'count_' + char2count[char] 
        if(count_char not in c[series]):
            c[series][count_char] = 0
    for rec_type in rec_types:
        ## default
        holder[series][rec_type][papid] = -1
        if(papid in data[rec_type]): 
            count_rectype = 'count_' + rec_type
            c[series][count_rectype] = c[series][count_rectype] + 1
            holder[series][rec_type][papid] = 1
    doc_ele = id_to_series_stats_ele(papid)
    ## the rest is all in the doc_ele! 
    if(doc_ele is None):
        return series_ele
    print("doc_ele exists")
    series_ele.append(doc_ele)
    stats = doc_ele.attrib
    for char in char2count:
        stats_char = 'stats_' + char
        count_char = 'count_' + char2count[char]
        if(stats_char in stats):
            if(int(stats[stats_char]) > 0):
                c[series][stats_char] += int(stats[stats_char]) 
                c[series][count_char] = c[series][count_char] + 1
            #break
        else:
            c[series][count_char] = c[series][count_char] + 1
    return series_ele


def write_missing(series, big_type, small_type, full=False):
    in_big_holder = remove_values_from_dict(holder[series][big_type], -1)
    in_small_holder = remove_values_from_dict(holder[series][small_type], -1)
    if(full):
        diff = holder[series][full]
    else: 
        diff = diff_between_holder_parts(in_big_holder, in_small_holder)
    has_missing[small_type] = len(diff)
    ## -1 is a bad cheat
    #print('diff ' + big_type + ' ' + small_type + str(len(diff)))
    #print(diff)
    # print('missing ' + small_type + ' ' + str(has_missing[small_type]))
    #missing_built_count = build_missing(diff, series, big_type, small_type)
    group_out_dir = dirs['group_out'] + '/' + group 
    print(group_out_dir)
    #     for series in holder:
    #         print(series)
    root_ele = etree.Element('series')
    root_ele.set('version', '1.0')
    root_ele.set('date', today)
    if(full):
        root_ele.set('full', full)
    root_ele.set('pretty_date', pretty_today)
    root_ele.set('group', group)
    root_ele.set('series', series)
    root_ele.set('missing', small_type)
    root_ele.set('missing_from', big_type)
    count_missing = 0
    for papid in diff:
        ## should be paper
        papers_ele = etree.Element('papers')
        papers_ele.set('handle', papid)
        if(small_type == 'recika'):
            papers_ele.set('perenfurl', cec.papid2perenfurl(papid))
        print("papid is " + papid)
        root_ele.append(papers_ele)
        count_missing = count_missing + 1
    xml_fufi = group_out_dir  + '/missing/' + series + \
        '_' + small_type + '.xml'
    html_fufi = group_out_dir + '/missing/' + series + \
        '_' + small_type + '.html'
    if(not len(diff)):
        if(os.path.exists(xml_fufi)):
            os.remove(xml_fufi)
        if(os.path.exists(html_fufi)):
            os.remove(html_fufi)
        print("nothing missing for " + big_type + " - " + small_type)
        return 0
    with_files.install_xml(root_ele, xml_fufi)
    mdate = with_files.mdate(xml_fufi, pretty=1)
    pretty_date_param = etree.XSLT.strparam(mdate)
    page_type_param = etree.XSLT.strparam(big_type)
    html = stats_missing_sheet(root_ele,
                              **{'date_pretty': pretty_date_param},
                              **{'page_type': page_type_param})
    print("I write " + html_fufi)
    with_files.install_html(html, html_fufi)
    with_files.install_xml(root_ele, xml_fufi)
    #return count_missing
    #if(count_has_missing != missing_built_count):
    #    print("missings mismatch")
    #    quit()
    return 1
    

groups_ele = etree.Element('groups')
groups_index_html_fufi = html_dir + '/' + 'index.html'
groups_index_xml_fufi = html_dir + '/' + 'index.xml'

for group in groups:
    c = {}
    ###
    #if(group == 'Christopher-Baum'):
    #    continue
    ###
    init_holder()
    group_ele = etree.Element('group')
    group_ele.set('handle', group)
    groups_ele.append(group_ele)
    group_html_dir = html_dir + '/' + group
    if(not os.path.isdir(group_html_dir)):
        os.mkdir(group_html_dir)
    group_dir = dirs['groups'] + '/' + group 
    missing_built = {}
    ## get the group data file
    data_file_glob = group_dir + '/perpers*.xml'
    data_files = glob.glob(data_file_glob)
    if(len(data_files) == 0):
        print("I see no data file for this group at " + data_file_glob)
        quit()
    if(len(data_files) > 1):
        print("I see several data files for this group at " + data_file_glob)
        quit()
    data_fufi = data_files[0]
    data_bana = os.path.basename(data_fufi)
    for series_type in series_types:
        ## renew series element, globally defined
        series_ele = etree.Element('series')
        series_ele.set('group', group)
        series_ele.set('series_type', series_type)
        in_fufi = group_dir + '/' + series_type + '.txt'
        print("series_type is " + series_type)
        ## read items
        with open(in_fufi) as in_file:
            papers_list = in_file.read().splitlines() 
            for papid in papers_list:
                ## adds to items
                holder[series_type]['items'][papid] = 1
                series_ele = add_paper_to_series(papid, series_type,
                                                 series_ele)
        #print(c[series]['count_records'])
        xml_fufi = group_html_dir + '/' + series_type + '.xml'
        html_fufi = group_html_dir + '/' + series_type + '.html'
        with_files.install_xml(series_ele, xml_fufi)
        mdate = with_files.mdate(xml_fufi, pretty=1)
        pretty_date_param = etree.XSLT.strparam(mdate)
        html = stats_series_sheet(series_ele,
                                  **{'date_pretty': pretty_date_param})
        print("I write " + html_fufi)
        with_files.install_html(html, html_fufi)
        #et.write(xml_fufi, pretty_print=True)
        print("I wrote " + xml_fufi)
        ## write the full set of items into missing
        write_missing(series_type, 'items', 'records', full='records')
        write_missing(series_type, 'records', 'futlis')
        write_missing(series_type, 'futlis', 'warcs')
        write_missing(series_type, 'warcs', 'pdf_warcs')
        write_missing(series_type, 'pdf_warcs', 'jsons')
        write_missing(series_type, 'jsons', 'recika')
    ## build cover
    root_ele = etree.Element('table')
    root_ele.set('version', '1.0')
    root_ele.set('date', today)
    root_ele.set('group', group)
    root_ele.set('bana', data_bana)
    for series_type in series_types:
        build_xml(series_type, holder[series_type])
    group_xml_cover_fufi = group_html_dir + '/index.xml'    
    with_files.install_xml(root_ele, group_xml_cover_fufi)
    group_html_cover_fufi = group_html_dir + '/index.html'
    print("I install " + group_html_cover_fufi)          
    #print(etree.tostring(root_ele, pretty_print=True).decode('utf-8'))
    group_html = group_index_sheet(root_ele)
    #print(group_html_cover_fufi)
    with_files.install_html(group_html, group_html_cover_fufi)
    #group_html.write_output(group_html_cover_fufi)
    #print(holder_futlis)
    #for holder in holders:
    #    if(holder == holder_records):
    #        xml_holder(holder, 'itemsrecords')
    with_files.install_xml(groups_ele, groups_index_xml_fufi)
    groups_index_html = groups_index_sheet(groups_ele)
    with_files.install_html(groups_index_html, groups_index_html_fufi)
