import csv, sys, json
import logging
import math, random
import time

import requests
from lxml import etree

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

output = sys.argv[1]

# common_user_agents.json from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/
common_user_agents = [
    row["useragent"] for row in json.load(open("common_user_agents.json"))
]


def get_headers():
    user_agent = random.choice(common_user_agents)
    headers = {
        "User-Agent": user_agent,
    }
    return headers


def list_projects():
    URL = "https://launchpad.net/projects/+all?batch=300"

    projects = []
    page_num = 1

    while True:
        response = requests.get(URL, headers=get_headers()).text
        html = etree.HTML(response)
        if page_num == 1:
            num_projs = int(
                html.xpath('//div[@class="main-portlet"][1]/p/strong/text()')[0]
            )
            print(f"{num_projs} projects registered in launchpad.net")

        proj_divs = html.xpath('//table[@id="product-listing"]/div')
        logger.info(f"page {page_num}: {URL}, {len(proj_divs)} projects")
        page_num += 1

        for div in proj_divs:
            names = div.xpath(".//a/text()")
            urls = div.xpath(".//a/@href")
            proj_name = names[0]
            proj_url = f"https://launchpad.net{urls[0]}"
            description = div.xpath(".//div/div[1]/text()")[0]
            maintainer_name = names[1] if len(names) > 1 else None
            maintainer_url = (
                f"https://launchpad.net{urls[1]}" if len(urls) > 1 else None
            )
            register_dt = div.xpath(".//time/@datetime")[0]
            projects.append(
                (
                    proj_name,
                    proj_url,
                    description,
                    maintainer_name,
                    maintainer_url,
                    register_dt,
                )
            )

        next_link = html.xpath('//a[@id="upper-batch-nav-batchnav-next"][1]')
        if next_link:
            URL = next_link[0].attrib["href"]
            time.sleep(1)
        else:
            break
    with open(output+".csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "project_name",
                "project_url",
                "description",
                "maintainer_name",
                "maintainer_url",
                "register_datetime",
            ]
        )
        writer.writerows(projects)


def parse_code_page(project_url: str, page_num: int):
    repos = []
    response = requests.get(project_url, headers=get_headers())
    if response.status_code == requests.codes.ok:
        html = etree.HTML(response.text)
        git_repos_table = html.xpath('//*[@id="gitrepositories-table-listing"]')
        if git_repos_table:
            git_repos_table = git_repos_table[0]

            nav = git_repos_table.xpath("./table[2]/tbody/tr/td")
            if len(nav) < 2:
                logger.info(f"{project_url}: no git repositories")
                return repos, 0

            repo_links = git_repos_table.xpath(
                "./table[@class='listing']/tbody/tr/td/a/text()"
            )
            for link in repo_links:
                repos.append(f"https://git.launchpad.net/{link.split(':', 1)[1]}")

            if page_num == 1:
                nav_index = nav[0]
                num_repos = int(
                    nav_index.xpath("string()")
                    .replace(" ", "")
                    .replace("\n", "")
                    .split("f")[1]
                    .split("r")[0]
                )
                logger.info(f"{project_url}: {num_repos} repositories")
                logger.info(f"\tpage {page_num}: {len(repo_links)} repositories")
                return repos, num_repos
            else:
                logger.info(f"\tpage {page_num}: {len(repo_links)} repositories")
                return repos, 0
        else:
            logger.info(f"{project_url}: no git repositories")
            return repos, 0
    else:
        logger.error(f"{project_url}: {response.status_code}")
        return repos, 0


def list_repos_per_proj(project_url: str):
    res = []

    repos, num_repos = parse_code_page(project_url, 1)
    res.extend(repos)

    for i in range(1, math.ceil(num_repos // 100) + 1):
        repos, _ = parse_code_page(
            project_url + f"/+code?repo_memo={i*100}&repo_start={i*100}", i + 1
        )
        res.extend(repos)
        time.sleep(random.random())

    return res


def list_repositories():
    project_urls = []

    with open(output+".csv") as csvfile:
        reader = csv.reader(csvfile)
        next(reader)
        for row in reader:
            project_urls.append((row[0], row[1]))

    # well, project ubuntu does not appear in the https://launchpad.net/projects/+all page.
    # so I add it manually :)
    if "https://launchpad.net/ubuntu" not in project_urls:
        project_urls.append(("Ubuntu","https://launchpad.net/ubuntu"))
    repository_urls = {}
    for proj_name, proj_url in project_urls:
        url = "https://code." + proj_url.split("//", 1)[1]
        repos = list_repos_per_proj(url)
        time.sleep(random.random())
        repository_urls[proj_name] = repos

    with open(output+".json", "w") as f:
        json.dump(repository_urls, f)


def print_repositories():
    repos = []
    with open(output+".json") as f:
        data = json.load(f)
    for _ in data.values():
        repos.extend(_)
    with open(output, "w") as f:
        for r in repos:
            f.write(f"{r}\n")


if __name__ == "__main__":
    #this runs a few days
    list_projects()
    #this runs a few days
    list_repositories()
    print_repositories()
