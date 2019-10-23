import sys
import re, pymongo, json
import requests, time


jsonDict = {}
#url = 'https://api.bitbucket.org/2.0/repositories/?pagelen=100&after=2017-11-18'
#url = 'https://api.bitbucket.org/2.0/repositories/?pagelen=100&before='+sys.argv[2]+'&after='+sys.argv[1]
url = 'https://api.bitbucket.org/2.0/repositories/?pagelen=100&after='+sys.argv[1]
before = ''
if len(sys.argv) > 3:
  before = sys.argv[3]
  url = url + '&before='+sys.argv[3]

client = pymongo.MongoClient()
dbname = sys .argv[2]
# Get a reference to a particular database
db = client [dbname]
# Reference a particular collection in the database
coll = db ['repos']

while True:
  time .sleep (3) 
  r = requests.get (url)
  t = r.text
  while "Rate limit for this resource" in t:
    time .sleep (100)
    r = requests.get (url)
    t = r.text
  try: 
    jsonDict = json.loads (t)
  except Exception as e:
     print (e)
     print (t)
     time .sleep (200)
     continue
  if 'values' in jsonDict:
    for prj in jsonDict ['values']:
      coll .insert (prj) 
  if 'next' not in jsonDict:
    print ("no next")    
    for k in jsonDict.keys ():
      print (str(k)+':'+str(jsonDict[k]))
    break
  else: 
    url = jsonDict['next']
    after=re.sub(r'T.*', '', re.sub(r'.*after=', '', url))
    if before is not '' and after > before:
       break
    print ('next='+str(url))

