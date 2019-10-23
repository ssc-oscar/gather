import sys, re, pymongo, json
import requests


jsonDict = {}

client = pymongo.MongoClient ()
# Get a reference to a particular database
args = list(sys.argv)
args.pop (0)
db = client [args.pop (0)]
# Reference a particular collection in the database
coll = db [args.pop (0)]
q = args.pop (0)
#print (q)
query = json.loads(q)
# { "last_activity_at":{ $gt : "2018-11-10T03:25:57.704196+00:00" } }

rest = args
#for r in coll .find ({},timeOut = False):  
for r in coll .find (query):  
  if (rest[0] in r and r[rest[0]] is not None):
   n = r[rest[0]]
   if (type(n) is not str): n = str (n)
   for i in range (1, len(rest)):
    if (rest[i] not in r or r[rest[i]] is None): n1 = ''
    else:
     if (type(r[rest[i]]) is not str): 
       #if type(r[rest[i]]) is unicode:
       #  n1 = r[rest[i]].encode('ascii', errors='ignore')
       #else:
       n1 = str (r[rest[i]])
     else: 
      n1 = re.sub('[\r\n]', 'NEWLINE', r[rest[i]])
      n1 = re.sub(';', 'SEMICOLON', n1)
    n = n + ';' + n1
   print (n.encode('ascii', errors='ignore'))
