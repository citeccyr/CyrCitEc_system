#!/bin/sh

# set working directory
WD=/home/cec/vic/TK
cd $WD || die;
echo -n "harvesting in "; pwd

# set date to N+1 days back to run harvest every N days
#from=`date -v-2d +%Y-%m-%d`
from=$1

# 2-level  backup
rm -rf dst1.tmp
mv dst0.tmp  dst1.tmp
mv dst.tmp  dst0.tmp
mkdir       dst.tmp

# archive and series descriptors
cp structure/*.xml dst.tmp

# journals
#       - backup
rm -rf src-com_2311_604.tmp.0
mv src-com_2311_604.tmp src-com_2311_604.tmp.0

#       - download new records since $from
./oai-wget 'http://elib.sfu-kras.ru/oai/request?set=com_2311_604\&metadataPrefix=qdc' src-com_2311_604.tmp $from

#       - convert to 'socionet' xml format
cat src-com_2311_604.tmp/* | ./conv.pl


# conference
#./oai-fetch http://elib.sfu-kras.ru/oai/request?set=com_2311_3245\&metadataPrefix=qdc src-com_2311_3245.tmp
#exit

# thesis
#./oai-fetch http://elib.sfu-kras.ru/oai/request?set=com_2311_21660\&metadataPrefix=qdc src-com_2311_21660.tmp
#exit

# discard not well-formed xmls
sh ./nwf

# save the records into repository
## mkdir /home/ftp/socionet/sfukras
## ~s/bin/cp2pre_db.pl    -s dst.tmp -n ranepa -t /home/ftp/socionet/sfukras
# -- this script adds/fixes some elements and tests equality of the records
