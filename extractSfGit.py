'''
Script used to extract git urls of sourceforge projects
Uses the 'git ls-remote' command to test if a repo exists
'''
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

gitBase = 'https://git.code.sf.net/p/{}/{}/' # base url
params = ['git', 'ls-remote'] # subprocess parameters
# last_object = ObjectId("5c2f59fd256eee0016f01e8b") # used for script crashes

# the query itself (currently uses the last object when script crashed)
cursor = coll.find({"git": None}), no_cursor_timeout=True)

# traverse database and attempt 'git ls-remote' on two options (code vs. git)
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
# close the cursor since we set it to no timeout
cursor.close()	
