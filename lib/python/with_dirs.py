import os.walk


def list_files(input_dir):
    # onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]
    files = []
    for (dirpath, dirnames, filenames) in os.walk(input_dir):
        print(filenames)
        files.extend(filenames)
    return files
    

