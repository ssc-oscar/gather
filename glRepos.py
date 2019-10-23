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

beginurl = "https://gitlab.com/api/v4/projects?archived=false&membership=false&order_by=created_at&owned=false&page={}&per_page=99&simple=false&sort=desc&starred=false&statistics=false&with_custom_attributes=false&with_issues_enabled=false&with_merge_requests_enabled=false"

gleft = 0
success = "Successfully loaded page {}. Got {} repos, current total is {}"

header = {'per_page': str(99)}

# check remaining query chances for rate-limit restriction
def wait(left):
    global header
    while (left < 20):
        l = requests.get('https://gitlab.com/api/v4/projects', headers=header)
        if (l.ok):
            left = int(l.headers.get('RateLimit-Remaining'))
        print("Waiting for rate limit...")
        time.sleep(60)
    return left

# send queries and extract urls
def get(url, coll):

    global gleft
    global header
    global bginnum
    gleft = wait(gleft)
    total = 0

    try:
        r = requests .get(url, headers=header)
        time.sleep(0.5)
        # got blocked
        if r.status_code == 403:
            return "got blocked", str(bginnum)
        if (r.ok):
            gleft = int(r.headers.get('RateLimit-Remaining'))

            # get total number of pages (i.e. get last possible page)
            lll = r.headers.get('Link')
            ll = lll.replace(';', ',').split(',')
            url = ll[ll.index(' rel="next"') -
                    1].replace('<', '').replace('>', '').lstrip()
            last = re.findall(r'&page=(\d+)&', url)
            if (len(last) == 1):
              last = int(last[0])

            t = r.text
            array = json.loads(t)
            total += len(array)
            print(success.format(begin, len(array), total))

            for el in array:
                el['page_number'] = begin
                coll.insert(el)

            pageNum = int(r.headers.get('X-Next-Page'))
            consecutiveEmpty = 0
            while (pageNum):
                gleft = int(r.headers.get('RateLimit-Remaining'))
                gleft = wait(gleft)
                # extract next page url
                url = beginurl.format(pageNum)
                # try:
                r = requests .get(url, headers=header)
                if r.status_code == 403:
                    return "got blocked", str(bginnum)
                if (r.ok):
                    lll = r.headers.get('Link')
                    t = r.text
                    array1 = json.loads(t)
                    total += len(array1)
                    print(success.format(pageNum, len(array1), total))

                    for el in array1:
                        el['page_number'] = pageNum
                        coll.insert(el)

                    if (r.headers.get('X-Next-Page')):
                        pageNum = int(r.headers.get('X-Next-Page'))
                        consecutiveEmpty = 0
                    else:
                        sys.stderr.write("Can't find next page from:{}{}{}".format('\n', url, '\n'))
                        pageNum += 1
                        consecutiveEmpty += 1
                        if consecutiveEmpty > 4:
                            sys.stderr.write("Page {} is 5 consecutive empty pages. Exiting".format(pageNum))
                            return
                        continue
        else:
            sys.stderr.write("url can not found:\n" + url + '\n')
            return

    except requests.exceptions.ConnectionError:
        sys.stderr.write('could not get ' + url + '\n')
    except Exception as e:
        sys.stderr.write(url + ';' + str(e) + '\n')

#start retrieving
get(beginurl.format(begin),coll)
