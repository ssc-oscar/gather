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

# Functions

# wait for reset if we exhaust our number of calls
def wait(reset):
  now = datetime.now()
  then = datetime.strptime(reset, "%Y-%m-%dT%H:%M:%SZ")
  wait = (then-now).total_seconds() + 30
  time.sleep(wait)

# helper function to loop through and insert repos into mongo db
def gatherData (res):
  global total
  repos = res['data']['search']['nodes']
  #dt = res['data']['search']['nodes']
  for i in repos:
    coll.insert(i)
    #for repo in repos:
    #  coll.insert({**repo['node'],**{'period': begin}})
  total += len(repos)

  output = "Got {} repos. Total count is {}. Have {} calls remaining."
  print (output.format(len(repos), total, remaining))

# dict mapping for splitting the day into hour sections 
def tokenperiod(token_id):
    switcher = {
        "0": "T00:00:00Z-T04:00:00Z",
        "1": "T04:00:00Z-T08:00:00Z",
        "2": "T08:00:00Z-T12:00:00Z",
        "3": "T12:00:00Z-T16:00:00Z",
        "4": "T16:00:00Z-T20:00:00Z",
        "5": "T20:00:00Z-T00:00:00Z",
    }

    return switcher.get(token_id, "invalid")

# Main

# get num for token and GITHUB API token from command line
token_id, token = sys.stdin.readline().strip().split(' ')

start_tokper, end_tokper = tokenperiod(token_id).split('-')

date = datetime.today()

begin = date - timedelta(days = 1)
start = begin.strftime("%Y-%m-%d") + start_tokper

if token_id == "5":
  end_toStr = date.strftime("%Y-%m-%d") + end_tokper
else:
  end_toStr = begin.strftime("%Y-%m-%d") + end_tokper

end_time = datetime.strptime(end_toStr, "%Y-%m-%dT%H:%M:%SZ")
interval = datetime.strptime(start, "%Y-%m-%dT%H:%M:%SZ")

# DB info
client = pymongo.MongoClient()
dbName = sys.argv[1] # db name as second arg
collName = sys.argv[2] # coll name as third arga

db = client[dbName]
coll = db[collName]

url = 'https://api.github.com/graphql'
headers = {'Authorization': 'token ' + token}
total = 0
remaining = 5000

print (end_time.strftime("%Y-%m-%dT%H:%M:%SZ"))
print (interval.strftime("%Y-%m-%dT%H:%M:%SZ"))

# query that specifies which repos and what content to extract
query = '''{
  rateLimit {
    cost
    remaining
    resetAt
  }
  search(query: "is:public archived:false fork:false mirror:false pushed:%s..%s", type: REPOSITORY, first: 100) {
    repositoryCount
    pageInfo {
      hasNextPage
      endCursor
      startCursor
    }
    nodes {
        ... on Repository {
          nameWithOwner
          updatedAt
          createdAt
          pushedAt
          id
			 forkCount
          description
        }
      }
  }
}'''
jsonS = { 'query': query }


# driver loop that iterates through repos in 10 minute intervals
# iterates from the specified date up to the current time
while (interval < end_time):
  fromStr = interval.strftime("%Y-%m-%dT%H:%M:%SZ")
  toStr = (interval + timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ")
  nextQuery = query % (fromStr, toStr)
  jsonS['query'] = nextQuery

  if (token == ''):
    print("Please provide your Github API token in the script. Exiting.")
    sys.exit()

  r = requests.post(url=url, json=jsonS, headers=headers)
  if r.ok:
    try:
      res = json.loads(r.content)
      print("did it come here? {}".format(res['data']['search']['pageInfo']))
      remaining = res['data']['rateLimit']['remaining']
      reset = res['data']['rateLimit']['resetAt']
      if remaining < 11:
        wait(reset)

      repos = res['data']['search']['repositoryCount']
      hasNextPage = res['data']['search']['pageInfo']['hasNextPage']
      gatherData(res)

      # check if we got more than 100 results and need to paginate
      while (repos > 100 and hasNextPage):
        endCursor = res['data']['search']['pageInfo']['endCursor']
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
            repos = res['data']['search']['repositoryCount']
            hasNextPage = res['data']['search']['pageInfo']['hasNextPage']
            gatherData(res)
          except Exception as e:
            print(e)
    except Exception as e:
      print(e)
  interval += timedelta(minutes=10)

