from datetime import datetime 
import os
import lxml.etree as etree
import tempfile
import filecmp
import re
import errno
import json

from shutil import copyfile


re_changed = re.compile('It\\s+was\\s+last\\s+changed' +
                        '\\s+on\\s+\\d{4}.\\d{2}.\\d{2}\\.\\s*')
re_whitespace = re.compile('\\s+')


def prepare(filename):
    if not os.path.exists(os.path.dirname(filename)):
        try:
            os.makedirs(os.path.dirname(filename))
        except OSError as exc: # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise
        

def install_xml(ele, fufi):
    temp_file_name = tempfile.NamedTemporaryFile(delete=False).name
    et = etree.ElementTree(ele)
    et.write(temp_file_name, pretty_print=True)
    prepare(fufi)
    if(os.path.exists(fufi)):
        if(filecmp.cmp(temp_file_name, fufi, shallow=True)):
            os.remove(temp_file_name)
            return
    copyfile(temp_file_name, fufi)
    os.remove(temp_file_name)

    
def install_html(html, there_fufi):
    string = ''
    prepare(there_fufi)
    try:
        string = str(html)
    except Exception:
        string = html
    if(not os.path.exists(there_fufi)):
        there_file = open(there_fufi, 'w')
        there_file.write(string)
        there_file.close()
        return 1
    with open(there_fufi, "r") as there_file:
        old_string = there_file.read()
        old_string = normalize_for_change(old_string)
        new_string = normalize_for_change(string)
    if(old_string == new_string):
        return 0
    there_file = open(there_fufi, 'w')
    there_file.write(string)
    there_file.close()
    return 1


def slurp(fufi):
    with open(fufi, 'r') as file:
        string = file.read()
    return string

  
def normalize_for_change(string):
    norm_string = re_changed.sub('', string)
    norm_string = re_whitespace.sub('', norm_string)
    return norm_string


def mdate(fufi, pretty=False):
    date_format = "%Y-%m-%d"
    if(pretty):
        date_format = u'%Y\u2012%m\u2012%d'
    time = os.path.getmtime(fufi)
    time = datetime.utcfromtimestamp(time)
    mdate = time.strftime(date_format)
    return mdate


def load(fufi):
    with open(fufi) as the_file:
        data = json.load(the_file)
    return data


def age(fufi):
    mtime = os.path.getmtime(fufi)
    now = datetime.now().strftime('%s')
    age = int(now) - mtime
    return age

