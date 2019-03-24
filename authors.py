#!/usr/bin/env python3
import sys
import re
import pymongo
import json
import time
import datetime
import requests


# DB info
client = pymongo.MongoClient(host='da1')
dbname = sys.argv[1] # expects db name as second arg
collName = sys.argv[2] # expects collection name as third arg
db = client[dbname]
coll = db[collName]


na = 0;
aa = []
for line in sys.stdin:
   line = line .rstrip('\n')
   line = bytes(line, 'utf-8','ignore').decode('utf-8', 'ignore').encode("utf-8")
   if len (line) > 45570:
       print (line)
       next
   try: 
       el = json.loads (line)
       aa .append (el)
   except:
       print (line)
   na = na + 1
   if (na > 5000):
       coll.insert_many (aa)
       aa = []
       na = 0


