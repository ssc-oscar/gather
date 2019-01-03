#!/usr/bin/env python3
import sys
import re
import pymongo
import json
import time
import datetime
import requests

begin = sys.argv[1] # beginning page index from first arg

# DB info
client = pymongo.MongoClient()
dbname = sys.argv[2] # expects db name as second arg
collName = sys.argv[3] # expects collection name as third arg
db = client[dbname]
coll = db[collName]

beginurl = "https://gitlab.com/api/v4/projects?archived=false&membership=false&order_by=created_at&owned=false&page=" + begin + \
    "&per_page=99&simple=false&sort=desc&starred=false&statistics=false&with_custom_attributes=false&with_issues_enabled=false&with_merge_requests_enabled=false"

gleft = 0

header = {'per_page': str(99)}

# check remaining query chances for rate-limit restriction
def wait(left):
    global header
    while (left < 20):
        l = requests.get('https://gitlab.com/api/v4/projects', headers=header)
        if (l.ok):
            left = int(l.headers.get('RateLimit-Remaining'))
        time .sleep(60)
    return left

# send queries and extract urls
def get(url, coll):

    global gleft
    global header
    global bginnum
    gleft = wait(gleft)
    values = []
    size = 0

    try:
        r = requests .get(url, headers=header)
        time .sleep(0.5)
        # got blocked
        if r.status_code == 403:
            return "got blocked", str(bginnum)
        if (r.ok):

            gleft = int(r.headers.get('RateLimit-Remaining'))
            lll = r.headers.get('Link')
            t = r.text
            array = json.loads(t)

            for el in array:
                coll.insert(el)

            #next page
            while ('; rel="next"' in lll):
                gleft = int(r.headers.get('RateLimit-Remaining'))
                gleft = wait(gleft)
                # extract next page url
                ll = lll.replace(';', ',').split(',')
                url = ll[ll.index(' rel="next"') -
                         1].replace('<', '').replace('>', '').lstrip()

                try:
                    r = requests .get(url, headers=header)
                    if r.status_code == 403:
                        return "got blocked", str(bginnum)
                    if (r.ok):
                        lll = r.headers.get('Link')
                        t = r.text
                        array1 = json.loads(t)
                        for el in array1:
                            coll.insert(el)
                    else:
                        sys.stderr.write("url can not found:\n" + url + '\n')
                        return
                except requests.exceptions.ConnectionError:
                    sys.stderr.write('could not get ' + url + '\n')

        else:
            sys.stderr.write("url can not found:\n" + url + '\n')
            return

    except requests.exceptions.ConnectionError:
        sys.stderr.write('could not get ' + url + '\n')
    except Exception as e:
        sys.stderr.write(url + ';' + str(e) + '\n')

#start retrieving
get(beginurl,coll)
