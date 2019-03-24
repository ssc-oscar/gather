import sys, re, pymongo, json, time
import datetime
from requests.auth import HTTPBasicAuth
import requests


login = sys.argv [1]
passwd = sys.argv [2]
dbname = sys.argv [3]

client = pymongo.MongoClient (host="da1")
# Get a reference to a particular database
db = client [dbname]

baseurl = 'https://api.github.com/repositories'
#do for followers following starred subscriptions orgs gists repos events received_events 
collName = 'repos'
# Reference a particular collection in the database
coll = db [collName]

gleft = 0
frNum = sys.argv[4];

def wait (left):
  while (left < 20):
    l = requests .get('https://api.github.com/rate_limit', auth=(login,passwd))
    if (l.ok):
      left = int (l.headers.get ('X-RateLimit-Remaining'))
      reset = int (l.headers.get ('x-ratelimit-reset'))
      now = int (time.time ())
      dif = reset - now
      if (dif > 0 and left < 20):
        sys.stderr.write ("waiting for " + str (dif) + "s until"+str(left)+"s\n")
        time .sleep (dif)
    time .sleep (0.5)
  return left  

def get (url, fr, to):
  global gleft, frNum
  gleft = wait (gleft)
  values = []
  size = 0
  # sys.stderr.write ("left:"+ str(left)+"s\n")
  try:
    frNum = re .sub('^.*since=', '', url) 
    r = requests .get (url, auth=(login, passwd))
    time .sleep (0.5)
    if (r.ok):
      gleft = int(r.headers.get ('X-RateLimit-Remaining'))
      lll = r.headers.get ('Link')
      links = ['']
      if lll is not None: 
        links = lll.split(',')
      try: 
        t = r.content.decode ('utf-8', 'ignore')
      except Exception as e:
        print ("crashing with problem at:" + str(e))
        return ()
      #t = r.text
      size += len (t)
      #print (t)
      array = json.loads (t)
      ts = datetime.datetime.utcnow()
      mid = 0
      for el in array:
        mid = el ['id']
        if mid <= to: coll.insert (el)
      if mid >= to: 
        frNum = str(mid)
        print ('Finished')
        return
      while mid < to and ('; rel="next"' in  links[0]):
        gleft = int(r.headers.get ('X-RateLimit-Remaining'))
        gleft = wait (gleft)
        url = links[0] .split(';')[0].replace('<','').replace('>','');
        try: 
          frNum = re .sub('^.*since=', '', url) 
          r = requests .get(url, auth=(login, passwd))
          print (url)
          if (r.ok): 
            lll = r.headers.get ('Link')
            links = ['']
            if lll is not None: 
              links = lll .split(',')
            try: 
              t = r.content.decode ('utf-8', 'ignore')
            except Exception as e:
              print ("problem at:" + str(e))
              
            #t = r.text
            size += len (t)
            array = json.loads (t)
            #print ('len='+str(len(t)) + ' alen='+str(len(array)))
            for el in array:
              if el is not None and 'id' in el: 
                mid = el ['id']
                if mid <= to: coll.insert (el)
          else:
            links = ['']
        except requests.exceptions.ConnectionError:
          sys.stderr.write('could not get ' + links + ' for '+ url + '\n')   
          #print u';'.join((u, repo, t)).encode('utf-8') 
      print (url + ';' + t)
    else:
      print (url + ';ERROR')
  except requests.exceptions.ConnectionError:
    print (url + ';ERROR')


url = baseurl
while int(frNum)+100 < int(sys.argv[5]):
  try: 
    get (url+"?since="+frNum, int(frNum), int(sys.argv[5])) #44210000)
  except Exception as e:
    print ("crashed at:" + str(e) + ' frNum='+frNum)
