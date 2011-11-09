#!/usr/bin/env python

import subprocess
import threading
import Queue
import random

# wget -E -H -e robots=off --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)"  -kp https://www.facebook.com/terms.php
# TODO(dta) use multiprocessing module instead?
# TODO(dta) set flag -r l1

POOL_SIZE = 10
GLOBAL_UAS = ["Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)"]

QUEUE = Queue.Queue()


class TOSCrawler(threading.Thread):
    def __init__(self, queue):
        threading.Thread.__init__(self)
        self.queue = queue
    
    def process(self, data):
        url = data['url']
        if 'UAs' in data:
            UAs = data['UAs']
        else:
            UAs = GLOBAL_UAS
        if 'xpath' in data:
            xpath = data['xpath']
        # TODO: do wget lookup
        print "Crawling %s\n" % url
        # todo add 
        args = ['wget', '-H', '-p', '-e', 'robots=off', '-o', '%s_wget.log' % url, '-U', random.choice(UAs), url]
        subprocess.call(args)
        # TODO(dta): rename directory tree, manipulate files

    def run(self):
        while True:
            data = self.queue.get()
            self.process(data)
            self.queue.task_done()

def ReadFormat(file_to_read):
    pass
    # read in from file (create test file for testing)
    # return results


def main():
    # 1. get results
    results = [{'url': 'google.com', 'xpath':'path'}, {'url':'facebook.com/terms.php'}]

    # 2. spawn thread pool
    for i in xrange(POOL_SIZE):
        t = TOSCrawler(QUEUE)
        t.daemon = True
        t.start()

    # 3. populate queue with results
    for r in results:
        QUEUE.put(r)

    QUEUE.join()


def CheckDiff():
    pass


main()
