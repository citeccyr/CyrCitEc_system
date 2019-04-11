import paths
import os
import glob
import cec

from lxml import etree
# from io import StringIO, BytesIO

series_types = ('citing_papers', 'cited_papers', 'linked_papers')
dirs = paths.dirs


def load_items(group):
    holder = {}
    group_dir = dirs['groups'] + '/' + group
    for series_type in series_types:
        holder[series_type] = {}
        in_fufi = group_dir + '/' + series_type + '.txt'
        if(not os.path.isfile(in_fufi)):
            holder[series_type]['items'] = []
            continue
        with open(in_fufi) as in_file:
            papers_list = in_file.read().splitlines() 
        holder[series_type]['items'] = {}
        for papid in papers_list:
            holder[series_type]['items'][papid] = 1
    return holder


def list():
    groups = []
    for candidate in glob.glob(dirs['groups'] + '/*'):
        if(not os.path.isdir(candidate)):
            continue
        groups.append(os.path.basename(candidate))
    return groups
            

def build_packets(group, records):
    holder = load_items(group)
    for series_type in holder:
        build_packet(group, series_type, holder[series_type]['items'], records)


def build_packet(group, series_type, holder, records):
    source_list = etree.XPath("//document/source")
    packet_ele = etree.Element('packet')
    parser = etree.XMLParser(recover=False)
    for papid in holder:
        peren_dir = cec.papid2peren(papid)
        if(not os.path.isdir(peren_dir)):
            #print("Where is " + peren_dir)
            continue
        summary_file = peren_dir + '/summary.xml'
        if(not os.path.isfile(summary_file)):
            print("Where is " + summary_file + ' for ' + ' group ' 
                  + group + ' series ' + series_type + '?')
            continue
        document_ele = etree.parse(summary_file).getroot()        
        print(etree.tostring(document_ele))
        for source_ele in (source_list(document_ele)):
            attributes = source_ele.attrib 
            papid = attributes['handle']
            if(papid not in records):
                packet_ele.append(document_ele)
                continue
            bibfile = records[papid]
            ## should not happen but let's just pass over it
            if(not os.path.isfile(bibfile)):
                continue
            try:
                bibdoc = etree.parse(bibfile, parser=parser)
            except etree.XMLSyntaxError:
                continue
            bibroot_ele = bibdoc.getroot()
            print(etree.tostring(bibroot_ele))
            source_ele.append(bibdoc.getroot())
            print(etree.tostring(source_ele))
            packet_ele.append(source_ele)
    out_file = dirs['group_out'] + '/' + group + '/' + series_type \
        + '.packet.xml'
    packet_et = etree.ElementTree(packet_ele)
    #print(packet_ele.toString())
    #print("group " + group)
    #print("series_type " + series_type)
    print(out_file)
    packet_et.write(out_file, pretty_print=True)
