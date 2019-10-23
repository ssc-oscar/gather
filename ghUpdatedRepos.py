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

# get all repos updated after this date
begin = sys.argv[1]
try:
  datetime.strptime(begin, '%Y-%m-%d')
except ValueError:
  raise ValueError("Incorrect beginning date format, should be YYYY-MM-DD")

# DB info
client = pymongo.MongoClient()
dbName = sys.argv[2] # db name as second arg
collName = sys.argv[3] # coll name as third arg
db = client[dbName]
coll = db[collName]

token = '9de7ae1b92c2af1b997c498a5f2605e0e4950300' # PROVIDE YOUR GITHUB API TOKEN HERE
url = 'https://api.github.com/graphql'
headers = {'Authorization': 'token ' + token}
start = begin + 'T00:00:00Z'
interval = datetime.strptime(start, "%Y-%m-%dT%H:%M:%SZ")
total = 0
remaining = 5000

# query that specifies which repos and what content to extract
query = '''{
  rateLimit {
    cost
    remaining
    resetAt
  }
  search(query: "is:public archived:false pushed:%s..%s", type: REPOSITORY, first: 100) {
    repositoryCount
    pageInfo {
      hasNextPage
      endCursor
      startCursor
    }
    edges {
      node {
        ... on Repository {
          nameWithOwner
          updatedAt
          createdAt
          isFork
          id
          description
        }
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
def gatherData(res):
  global total
  repos = res['data']['search']['edges']
  for repo in repos:
    coll.insert(repo['node'])
  total += len(repos)

  output = "Got {} repos. Total count is {}. Have {} calls remaining."
  print(output.format(len(repos), total, remaining))

# driver loop that iterates through repos in 10 minute intervals
# iterates from the specified date up to the current time
while (interval < datetime.now()):
  fromStr = interval.strftime("%Y-%m-%dT%H:%M:%SZ")
  toStr = (interval + timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ")
  nextQuery = query % (fromStr, toStr)
  jsonS['query'] = nextQuery

  if (token == ''):
    print("Please provide your Github API token in the script. Exiting.")
    sys.exit()

  r = requests.post(url=url, json=jsonS, headers=headers)
  res = json.loads(r.text)
  remaining = res['data']['rateLimit']['remaining']
  reset = res['data']['rateLimit']['resetAt']
  if remaining == 0:
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
    res = json.loads(r.text)
    try:
      remaining = res['data']['rateLimit']['remaining']
      reset = res['data']['rateLimit']['resetAt']
      if remaining == 0:
        wait(reset)
    except TypeError as e:
        print(e)

    repos = res['data']['search']['repositoryCount']
    hasNextPage = res['data']['search']['pageInfo']['hasNextPage']
    gatherData(res)

  interval += timedelta(minutes=10)
