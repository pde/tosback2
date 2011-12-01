#!/usr/bin/env python

import subprocess
import random
import git
import time
import os,os.path,shutil
import re
import sys
from lxml import etree

# TODO(dta) use multiprocessing module
# at some point in the future

GLOBAL_UAS = ["Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)"]
CODE_PATH = os.path.dirname(sys.argv[0])

class TOSCrawler(object):
    """Class to process xml files sequentially"""
    def __init__(self, xml_file_name=None):
        if xml_file_name:
            self.read(xml_file_name)

    def sanitize(self, filename):
        return re.sub(r'\W+', '-', filename)

    def read(self, file_name):
        """Parses XML file."""
        # TODO(dta) test on many-to-one urls
        xmlData = etree.parse(os.path.join(CODE_PATH, "..", "rules", file_name))
        data = {}
        for node in xmlData.iter():
            data[str(node.tag)] = node.attrib['name']
        return data

    def process(self, data):
        # 0. Determine parameters for this crawl
        assert "sitename" in data, "Every rule needs a sitename"
        sitename = data["sitename"]
        assert "docname" in data, "Every rule needs a docname"
        docname = self.sanitize(data["docname"])
        assert "url" in data, "Every rule needs a url"
        url = data["url"]

        recurse = "norecurse" not in data
        xpath = "xpath" not in data

        if 'UAs' in data:
            UAs = data['UAs']
        else:
            UAs = GLOBAL_UAS

        # 1. Prepare a directory for the crawl results
        target = os.path.join(CODE_PATH,"..","crawls",sitename,docname)
        rawtarget = os.path.join(CODE_PATH,"..","crawls",sitename,docname,"raw")
        reltarget = os.path.join("crawls", sitename, docname)
        if os.path.isdir(target):
            # rm -rf the previous crawl state
            shutil.rmtree(target)
        os.makedirs(rawtarget)

        # 2. Do wget lookup
        print "Crawling %s" % url
        args = [
            'wget', 
            # Obtain images, CSS, etc, even from other domains
            '--page-requisites',
            '--span-hosts',
            # Obtain the Terms of Service, even if j.random crawler is blocked
            '--execute', 'robots=off', 
            '--user-agent', random.choice(UAs), 
            # Put results in the right place
            '--directory-prefix', rawtarget,
            '--output-file', os.path.join(target,"wget.log"),
            # Format things for historical/offline browsing
            '--convert-links',
            '--adjust-extension',
            # Sensible timeout/retries
            '--timeout', '15',
            '--tries', '3',
            url]
        if recurse:
            args[-1:-1] = ['--recursive', '--level', '1']
        print "calling ", args
        subprocess.call(args)
        return reltarget


def main():
    # 1. make a git branch to work in
    branchname = "crawl-" + time.strftime("%Y-%m-%d-%H-%M-%S")
    repopath=os.path.join(CODE_PATH,"..")
    gitrepo = git.Repo(repopath)
    committed = False
    original_branch = gitrepo.active_branch
    try:
        gitrepo.create_head(branchname)
        gitrepo.branches[branchname].checkout()

        # 2. initialize TOSCrawler
        t = TOSCrawler()

        # 3. Traverse
        crawl_paths = []
        parsed_xml_files = []
        for fi in os.listdir(os.path.join(CODE_PATH,"..","rules")):
            if fi[-4:]!=".xml": continue
            print "Reading in XML file %s" % fi
            parsed_xml_files.append(t.read(fi))

        for data in parsed_xml_files:
            path = t.process(data)
            crawl_paths.append(path)

        # 4. commit results

        print "Committing results..."
        gitrepo.index.add(crawl_paths)
        commit_msg = "Crawl completed at " + time.strftime("%Y-%m-%d-%H-%M-%S")
        os.environ["GIT_AUTHOR_NAME"]="Robbie Robot"
        os.environ["GIT_AUTHOR_EMAIL"]="robots@dev.null"
        committed = gitrepo.index.commit(commit_msg)


    finally:
        original_branch.checkout()
        if not committed and ("--keep-failed" not in sys.argv):
            # We didn't finish the crawl; unless the user asked for it we
            # won't keep the result
            gitrepo.branches[branchname].delete(gitrepo,branchname)
            if branchname in gitrepo.branches:
                print "Failed to delete crawl branch %s for mysterious reasons" % branchname
            # PS -- who on earth designed this API

main()
