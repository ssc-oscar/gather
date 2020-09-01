'''
Script to scrape GitHub repos using the GraphQL API
Obtains all repos that have been updated AFTER a specified date
Scrapes all repos from that date up to the current time
'''
import requests
import json
import pymongo
from datetime import datetime, timedelta
import time
import sys

# DB info
client = pymongo.MongoClient()
dbName = sys.argv[1] # db name as second arg
collName = sys.argv[2] # coll name as third arg
token = sys.argv[3]

db = client[dbName]
coll = db[collName]

url = 'https://api.github.com/graphql'
headers = {'Authorization': 'token ' + token}
total = 0
remaining = 5000

# query that specifies which repos and what content to extract
query = '''{
  rateLimit {
    cost
    remaining
    resetAt
  }
  user (login:"%s") {
    login
    repositories (first:100) {
       totalCount
       pageInfo {
        hasNextPage
        endCursor
        startCursor
       }
       nodes {
          nameWithOwner
          parent { nameWithOwner }
          isFork
          }
       }
    }
}'''
jsonS = { 'query': query }

# wait for reset if we exhaust our number of calls
def wait(reset):
  now = datetime.now()
  then = datetime.strptime(reset, "%Y-%m-%dT%H:%M:%SZ")
  wait = (then-now).total_seconds() + 30
  time.sleep(wait)


# helper function to loop through and insert repos into mongo db
def gatherData (res):
  global total
  repos = res['data']['user']['repositories']['nodes']
  #dt = res['data']['search']['nodes']
  for i in repos:
    coll.insert(i)
    #for repo in repos:
    #  coll.insert({**repo['node'],**{'period': begin}})
  total += len(repos)

  output = "Got {} repos. Total count is {}. Have {} calls remaining."
  print (output.format(len(repos), total, remaining))


for line in sys.stdin:
# driver loop that iterates through repos in 10 minute intervals
# iterates from the specified date up to the current time
  owner = line .rstrip ()
  nextQuery = query % (owner)
  jsonS['query'] = nextQuery

  #print(nextQuery)
  if (token == ''):
    print("Please provide your Github API token in the script. Exiting.")
    sys.exit()

  r = requests.post(url=url, json=jsonS, headers=headers)
  if r.ok:
    try:
      print("did it come here?")
      print (r.text)
      res = json.loads(r.content)
      remaining = res['data']['rateLimit']['remaining']
      reset = res['data']['rateLimit']['resetAt']
      if remaining < 11:
        wait(reset)

      repos = res['data']['user']['repositories']['totalCount']
      hasNextPage = res['data']['user']['repositories']['pageInfo']['hasNextPage']
      gatherData(res)

      # check if we got more than 100 results and need to paginate
      while (repos > 100 and hasNextPage):
        endCursor = res['data']['user']['repositories']['pageInfo']['endCursor']
        print("Have to paginate, using cursor {}".format(endCursor))
        index = nextQuery.find("REPOSITORY") + len("REPOSITORY")
        pageQuery = nextQuery[:index] + ',after:"{}"'.format(endCursor) + nextQuery[index:]
        jsonS['query'] = pageQuery

        r = requests.post(url=url, json=jsonS, headers=headers)
        if r.ok:
          res = json.loads(r.text)
          try:
            remaining = res['data']['rateLimit']['remaining']
            reset = res['data']['rateLimit']['resetAt']
            if remaining < 11:
              wait(reset)
            repos = res['data']['user']['repositories']['totalCount']
            hasNextPage = res['data']['user']['repositories']['pageInfo']['hasNextPage']
            gatherData(res)
          except Exception as e:
            print(e)
    except Exception as e:
      print(e)
