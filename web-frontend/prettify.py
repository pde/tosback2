#!/usr/bin/env python

import bs4
import codecs
import sys

"""
Things to try:
find nice input for each thing? store this file?
GET ENCODINGS CORRECT!
Deal with malformed javascript or issues that stop parsing

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

def getAllText():
    #f = open(fname,'r')
    #fout = open(out_name,'w')
    #fout = codecs.open(out_name, mode='w', encoding='utf-8')
    #fout = codecs.open(sys.stdout, mode='w', encoding='utf-8')
    #doc = f.read()
    doc = sys.stdin.read()
    soup = bs4.BeautifulSoup(doc)
    for tag in soup.findAll(["script","style"]):    # Remove javascript strings
        tag.string = ""
    for string in soup.strings:
        if type(string) in [bs4.element.Comment,bs4.element.Doctype]:
            continue
        #y = type(string)
        #fout.write(unicode(y))
        
        x = unicode(string)
        # TODO(chris) edit encoding output?
        #print x
        #fout.write(x)
        print x.encode('ascii', 'replace')

#fname1 = 'C:/Users/Chris/tosback2-experimental-data/crawls/twitter.com/Terms-of-Service/raw/twitter.com/tos.html'
#fname1 = 'C:/Users/Chris/tosback2-old/crawls/apple.com/iTunes-Terms-of-Service/raw/www.apple.com/legal/itunes/us/terms.html'
#getAllText(fname1, 'C:/Users/Chris/tosback2/extra/what')
getAllText()

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