#!/usr/bin/python3

from urllib import request
import xml.etree.ElementTree as ET
import re, itertools, os, pymongo, sys

# DB info
client = pymongo.MongoClient()
dbname = sys.argv[1] # expects db name as first argument
collName = sys.argv[2] # expect collection name as second arg
db = client[dbname]
coll = db[collName]

# uri used to properly parse the XML files
uri = '{http://www.sitemaps.org/schemas/sitemap/0.9}'

# The base url for every project that we append project name to
url = 'https://sourceforge.net/projects/'

# Regex used to extract the project name from the XML values
p = re.compile('projects/(.+?)/')

# A set to keep track of all UNIQUE project names
projects = set()

def parseXML(fname):
    """
    Function that parses the XML file named fname
    Iterates through XML starting at the root and visits each child
    Each child that contains a project name is added to the set
    """
    tree = ET.parse(fname)
    root = tree.getroot()
    for repo in root:
        for elem in repo:
            if (elem.tag == uri + 'loc'):
                res = p.search(elem.text)
                if res != None:
                    proj = res.group(1)
                    projects.add(url + proj)

def get(page):
    """
    Function that downloads the XML file of specific page and parses
    The XML file is saved into dest and then removed after parsing
    """
    base = 'https://sourceforge.net/sitemap-{}.xml'.format(page)
    dest = 'sitemap-{}.xml'.format(page)

    try:
        print('Downloading ' + base)
        request.urlretrieve(base, dest)
        parseXML(dest)
        os.remove(dest)
    except Exception as e:
        print('Download ERROR: ', str(e))

# Driver loop to get all 172 site mappings
# Number of mappings found at https://sourceforge.net/sitemap.xml
for i in range(0, 173):
    get(i)

# Insert all projects into collection
for i, proj in enumerate(itertools.islice(projects, len(projects))):
    coll.insert({"url": proj, "source": "SourceForge", "git": None})

# Print how many projects we found
print("# projects: " + str(len(projects)))
