import urllib.parse
import os.path
import paths


def papid2peren(papid):
    #print(papid)
    papid = papid.lower()
    #print(papid)
    papid = papid.replace('repec', 'RePEc', 1)
    #print(papid)
    papid = papid.replace(':', '/', 3)
    #print(papid)
    basename = os.path.basename(papid)
    dirname = os.path.dirname(papid)
    pap_dir = urllib.parse.quote_plus(basename)
    peren = paths.dirs['peren'] + '/' + dirname + '/' + pap_dir
    return peren


def papid2perenfurl(papid):
    peren = papid2peren(papid)
    furl = '/data/' + peren[20:]
    return furl


# $id2file->{'spz'}=sub {
#   my $id=shift // confess "I need an identifier here.";
#   my $file=lc($id);
#   $file=~s|repec|RePEc|i;
#   $file=~s|:|/|;
#   $file=~s|:|/|;
#   $file=~s|:|/|;
#   $file=substr($file,0,$-[0]+1);
#   $file.=uri_escape(substr($id,$-[0]+1));
#   return $file;
# };

