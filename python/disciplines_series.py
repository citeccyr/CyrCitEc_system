#!/usr/bin/python3.7

#import subprocess
#import re
import json
import lxml.etree as etree

## local imports 
import paths
import with_files

files = paths.files

sheet = etree.XSLT(etree.parse(paths.xslts['stats']))

#print(files['disciplines'])
discipline_data = with_files.load(files['disciplines'])

#print(discipline_data)

  
def do_discipline(discipline):
    print('discipline is ' + discipline)
    stats_doc = etree.parse(files['stats'])
    table_ele = stats_doc.getroot()
    table_ele.set('discipline', discipline)    
    for series in discipline_data:
        ## ignore empty series
        if(not series):
            continue
    series_eles = table_ele.xpath('//series')
    for series_ele in series_eles:
        handle = series_ele.get('id')
        if(handle not in discipline_data):
            series_ele.getparent().remove(series_ele)            
            continue
        if(not discipline_data[handle].count(discipline)):
            series_ele.getparent().remove(series_ele)
        else:
            print(handle + ' is in discipline ' + discipline)
        #print(etree.tostring(table_ele).decode('utf-8'))
    stats_disciplines_file = files['stats']
    end = len(stats_disciplines_file) - 4
    xml_fufi = stats_disciplines_file[0:end] + '_' + discipline + '.xml'
    with_files.install_xml(table_ele, xml_fufi)
    print("I write " + xml_fufi)
    ## a questionalble choice for the change date
    mdate = with_files.mdate(xml_fufi, pretty=1)
    pretty_date_param = etree.XSLT.strparam(mdate)
    html_fufi = paths.dirs['group_out'] + '/' + discipline + '.html'
    html = sheet(table_ele, **{'date_pretty': pretty_date_param})
    print("I write " + html_fufi)
    with_files.install_html(html, html_fufi)
    

## gather groups from XSLT
xslt_dir = paths.dirs['xslt']
group_index_xslt_fufi = xslt_dir + '/groups_index.xslt.xml'
group_index_doc = etree.parse(group_index_xslt_fufi)
print(type(group_index_doc))
ns = {}
ns['x'] = "http://www.w3.org/1999/XSL/Transform"
ns['h'] = "http://www.w3.org/1999/xhtml"

## nos/nosdgqoei.xml:  <Code>economics</Code>
#known_disciplines = group_index_doc.xpath("//h:a[@class='discipline']", namespaces=ns)
# known_disciplines = group_index_doc.xpath("//h:a", namespaces=ns)
a_elements = group_index_doc.xpath("//h:a", namespaces=ns)
## we can't make it in the xpath
for a_element in a_elements:
    if(not a_element.get('class') == 'discipline'):
        continue
    href = a_element.get('href')
    ## take the .html out_dict
    discipline = href[:-5]
    do_discipline(discipline)

