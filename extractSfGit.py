import pymongo
import sys
import json
import re
import time
import requests
import subprocess
from bson.objectid import ObjectId

client = pymongo.MongoClient(host='da1')
dbname = sys.argv[1] # expects db name as first argument
collName = sys.argv[2] # expect collection name as second arg
db = client[dbname]
coll = db[collName]

gitBase = 'https://git.code.sf.net/p/{}/{}/'
params = ['git', 'ls-remote']
last_object = ObjectId("5c2f59fd256eee0016f01e8b")
cursor = coll.find({"git": None, "_id": {"$gt": last_object}}, no_cursor_timeout=True)

for doc in cursor:
	proj = re.search('projects\/(.+)', doc['url']).group(1)
	bases = [gitBase.format(proj, 'git'), gitBase.format(proj, 'code')]
	for base in bases:
		try:
			checkParams = params + [base]
			subprocess.check_output(checkParams)
			print(base + " exists!")
			coll.update_one({'_id': doc['_id']}, {'$set': {'http_url_to_repo': base}}, upsert=False)
		except subprocess.CalledProcessError as err:
			continue

cursor.close()	
