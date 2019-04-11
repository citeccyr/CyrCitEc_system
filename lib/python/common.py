#import time
import subprocess
#from pathlib import Path


def rsync(url , fufi):
    subprocess.run(['/usr/bin/rsync', '-va', url, fufi])


# mtime --> mage 
#def mage(pathname):
#    return time.time() - os.stat(pathname)[stat.ST_MTIME] 

#def get_url(url , out_fufi):
#    out_path = Path(out_fufi)
#    if(out_path.is_file() and (mage(tmp_fufi) < 24 * 3600)):
#        return
#    with urllib.request.urlopen(url) as response:
#        response_string = response.read().decode('utf-8')
#        text_file = open(out_fufi, "w")
#        text_file.write(response_string)
#        text_file.close()




