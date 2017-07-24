#!/usr/bin/python3

import time
import datetime
import json
import facebookinsights

FACEBOOK_PAGE_TOKEN = ''

page = facebookinsights.authenticate(token=FACEBOOK_PAGE_TOKEN)

dir(page.insights.get_raw)

latest = page.posts.latest(10).get()

dailyimpressions = page.insights.daily(['page_impressions', 'page_fan_adds']).range(months=1).get_raw()

jsonimpressions = ''

for day in dailyimpressions:
    #print(json.dumps(day, indent=1)
    #print()
    jsonimpressions = json.dumps(day, indent=1)


jsonimpressions2 = json.loads(jsonimpressions)

# This works, but empties the generator object for some fucking reasion
# TODO: Return variable list from R script and transform for Python; populate script to create a single json file in TRANSFROM
# TODO: Must reference an original list of tokens, as defined in a shell script? Take paramaters like twitter.py
