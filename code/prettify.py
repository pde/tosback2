import bs4
import codecs
import sys

"""
Things to try:
Give a certain list of tags, use only those
Get only the strings
find nice input for each thing? store this file?
GET ENCODINGS CORRECT!
Deal with malformed javascript or issues that stop parsing

WHY DO I HAVE CSS IN MY STRINGS?

Get parents of strings, so we know that we're not missing anything???
"""

TAGLIST_OLD = ['a','p','li','ul','ol','h1','h2','h3']
TAGLIST = ['p','ul','ol','h1','h2','h3','div']

def makeUseful(fname,out_name):
    f = open(fname,'r')
    fout = open(out_name,'w')
    doc = f.read()
    soup = bs4.BeautifulSoup(doc)
    #for tag in soup.findAll(True):  # Remove attributes to keep things clean
    #    tag.attrs = []
    #for tag in soup.recursiveChildGenerator():
    for tag in soup.findAll(True):
        tag.attrs=[]    # Remove attributes to keep things clean
        if isinstance(tag,bs4.Tag) and tag.name in TAGLIST:
            print(tag)
            fout.write(str(tag))

def getAllText(fname,out_name):
    f = open(fname,'r')
    fout = open(out_name,'w')
    fout = codecs.open(out_name, mode='w', encoding='utf-8')
    doc = f.read()
    soup = bs4.BeautifulSoup(doc)
    for tag in soup.findAll(["script"]):    # Remove javascript strings
        tag.string = ""
    for string in soup.strings:
        if type(string) in [bs4.element.Comment,bs4.element.Doctype]:
            continue
        x = unicode(string)
        # TODO(chris) edit encoding output?
        fout.write(x)
        #print x.encode('ascii', 'replace')

getAllText(sys.argv[1], sys.argv[2])

#for tag in soup.recursiveChildGenerator():
"""
for tag in soup.findAll(True):
    if tag.string == None:
        continue
    x =  unicode(tag.string)
    print tag, x.encode('ascii', 'replace')
    fout.write(x.encode('ascii', 'replace'))
for tag in soup.findAll(["script"]):
    tag.string = ""
    print type(tag)
for tag in soup.findAll(lambda x: type(x) == bs4.element.Comment):
    print repr(tag.string)
for tag in soup.findAll(True):
    print type(tag)
"""