
import paths
import with_dirs
#    from os import listdir
#from os.path import isfile, join

dirs = paths.dirs                                                                              
#files = paths.files

#from os import walk

f = []
#for (dirpath, dirnames, filenames) in walk(mypath):
#    f.extend(filenames)
#    break


def bib():
    files = with_dirs.list_files(dirs['input'])
