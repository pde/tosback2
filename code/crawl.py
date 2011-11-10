#!/usr/bin/env python

import subprocess
import random
import git
import time
import os,os.path,shutil
import sys
from lxml import etree

# TODO(dta) use multiprocessing module
# at some point in the future

GLOBAL_UAS = ["Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)"]
OPERATING_PATH = os.path.dirname(sys.argv[0])

class TOSCrawler(object):
    """Class to process xml files sequentially"""
    def __init__(self, xml_file_name=None):
        if xml_file_name:
            self.read(xml_file_name)

    def read(self, file_name):
        """Parses XML file."""
        # TODO(dta) test on many-to-one urls
        xmlData = etree.parse(file_name)
        data = {}
        for node in xmlData.iter():
            self.data[str(node.tag)] = node.attrib['name']

    def process(self):
        # 0. Determine parameters for this crawl
        assert "sitename" in self.data, "Every rule needs a sitename"
        sitename = self.data["sitename"]
        assert "docname" in self.data, "Every rule needs a sitename"
        docname = self.data["docname"]
        assert "url" in self.data, "Every rule needs a url"
        url = self.data["url"]

        recurse = "norecurse" not in self.data
        xpath = "xpath" not in self.data

        if 'UAs' in self.data:
            UAs = self.data['UAs']
        else:
            UAs = GLOBAL_UAS

        # 1. Prepare a directory for the crawl results
        target = os.path.join(operating_path,"..","crawls",sitename,docname)
        if os.path.isdir(target):
            # rm -rf the previous crawl state
            shutils.rmtree(target)
        os.path.mkdirs(target)
        os.path.chdir(target)

        # 2. Do wget lookup
        print "Crawling %s\n" % url
        args = [
            'wget', 
            # Obtain images, CSS, etc, even from other domains
            '--page-requisites',
            '--span-hosts',
            # Obtain the Terms of Service, even if j.random crawler is blocked
            '--execute', 'robots=off', 
            '--user-agent', random.choice(UAs), 
            # Put results in the right place
            '--directory-prefix', target,         
            # '--output-file', '%s_wget.log' % url,   # URLs are not safe filenames
            '--output-file', 'crawled-terms-of-service.html'
            # Format things for historical/offline browsing
            '--convert-links',
            '--adjust-extension',
            url]
        if recurse:
            args[-1:-1] = ['--recursive', '--level', '1']
        subprocess.call(args)
        os.path.chdir(operating_path)
        # TODO(dta): rename directory tree, manipulate files


def main():
    # 1. make a git branch to work in
    branchname = "crawl-" + time.strftime("%Y-%m-%d-%H-%M-%S")
    gitrepo = git.Repo("..")
    gitrepo.branches[branchname]

    # 2. initialize TOSCrawler
    t = TOSCrawler()

    # 3. Traverse
    for fi in os.listdir("../rules"):
        if fi[-4:]!=".xml": continue
        print "Reading %s" % fi
        t.read(fi)
        t.process()


main()
