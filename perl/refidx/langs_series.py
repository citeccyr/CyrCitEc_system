#!/usr/bin/python3.7

import subprocess
import re
import lxml.etree as etree

import sys
sys.path.append("/home/cec/lib/python")

## local imports 
import paths
import with_files

files = paths.files
sheet = etree.XSLT(etree.parse(paths.xslts['stats']))


def do_lang(lang):
    stats_doc = etree.parse(files['stats'])
    table_ele = stats_doc.getroot()
    table_ele.set('lang', lang)    
    lang_ele = get_langs_series_xml()
    valid_series_starts = lang_ele.xpath('//' + lang + '/text()')
    series_eles = table_ele.xpath('//series')
    #print(series_eles) 
    exit()
    for series_ele in series_eles:
        handle = series_ele.get('id')
        is_valid = 0
        for valid_start in valid_series_starts:
            if(handle.startswith(valid_start)):
                is_valid = 1
                break
        if(not is_valid):
            series_ele.getparent().remove(series_ele)
    #print(etree.tostring(table_ele).decode('utf-8'))
    stats_lang_file = files['stats']
    end = len(stats_lang_file) - 4
    xml_fufi = stats_lang_file[0:end] + '_' + lang + '.xml'
    with_files.install_xml(table_ele, xml_fufi)
    ## a questionalble choice for the change date
    mdate = with_files.mdate(xml_fufi, pretty=1)
    pretty_date_param = etree.XSLT.strparam(mdate)
    html_fufi = paths.dirs['group_out'] + '/' + lang + '.html'
    html = sheet(table_ele, **{'date_pretty': pretty_date_param})
    #print("I write " + html_fufi)
    with_files.install_html(html, html_fufi)
    

def get_langs_series_xml():
    age = with_files.age(files['langs_series'])
    if(age < 24 * 60 * 60):
        doc = etree.parse(files['langs_series'])
        return doc.getroot()
    #shell_get_alist = 'ssh cyrcitec@socionet.ru cat A-list'
    shell_get_alist = 'cat A-list'
    re_alist_line = re.compile('\\s+')
    get_alist = subprocess.Popen([shell_get_alist], shell=True,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT)
    out_alist, err_alist = get_alist.communicate()
    lines_alist = out_alist.split(b'\n')    
    langs_ele = etree.Element('langs')
    for line in lines_alist:
        line = line.decode('utf-8')
        matches = re_alist_line.split(line)
        if(len(matches) == 1):
            continue
        if(len(matches) == 3):
            ru_ele = etree.Element('ru')
            ru_ele.text = matches[0].lower()
            langs_ele.append(ru_ele)
            continue
        en_ele = etree.Element('en')
        en_ele.text = matches[0].lower()    
        langs_ele.append(en_ele)
    print(files['langs_series'])
#    exit()
#    with_files.install_xml(langs_ele, files['langs_series'])
    with_files.install_xml(langs_ele, '/home/prl/langs_series_ru.xml')
    #print(etree.tostring(langs_ele).decode('utf-8'))
    return langs_ele
    

do_lang('ru')
#do_lang('en')
