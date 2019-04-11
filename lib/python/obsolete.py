#
### from group.py
#def id_to_bibfile(handle, series):    
#    full_handle = handle
#    if(series not in holder):
#        holder[series] = {}
#    ## items is everything we have
#    holder[series]['items'][full_handle] = 1
#    if(handle.startswith('repec')):
#        handle = handle[6:]
#    if(handle.startswith('spz')):
#        handle = handle[4:]
#        matches = re_cyberleninka.search(handle)        
#        if(matches):
#            first_number = matches.group(1)
#            second_number = matches.group(2)
#            file = dirs['input'] + '/cyberleninka/' + first_number + '/' \
#                + second_number + '.xml'
#            if(os.path.isfile(file)):
#                holder[series]['records'][full_handle] = 1
#                return file    
#    ## Vic does not handle the slash
#    handle = handle.replace('/', '-')
#    data_file = handle.replace(':' , '/', 1)
#    dir_part = data_file.partition(':')[0]
#    file_part = dir_part.replace('/', '', 1)
#    file_part = file_part.replace(':', '', 1)
#    local_id = handle.split(':')[2]
#    file = dirs['input'] + '/' + dir_part + '/' + file_part + local_id + '.xml'
#    if(os.path.isfile(file)):
#        holder[series]['records'][full_handle] = 1
#        return file
#    ## second approach
#    local_id = handle.split(':')
#    ## don't know how to say go to the end
#    local_id = local_id[2:10000]
#    local_id = ':'.join(local_id)
#    file = dirs['input'] + '/' + dir_part + '/' + file_part + local_id + '.xml'
#    if(os.path.isfile(file)):
#        holder[series]['records'][full_handle] = 1
#        return file    
#    print("No_bibfile for record " + full_handle + ' at ' + file)
#    holder[series]['records'][full_handle] = -1
#    return ""

