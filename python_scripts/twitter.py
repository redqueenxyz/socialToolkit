#!/usr/bin/python3
# Source: https://github.com/t-pfaff/twitter-analytics-export

import requests
import re
import time
import json
import datetime
import urllib.parse
from io import StringIO
import codecs
import csv
import argparse
import os
import math

#TODO: Modify TwitteR_Flow to Twitter Aggregator; clean up script for agent


def twitter_flow(USERNAME, PASSWORD, ANALYTICS_ACCOUNT, NUM_DAYS, OUTPUT_DIRECTORY):
    user_agent = {'User-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36'}
    session = twitter_login(USERNAME, PASSWORD, user_agent)

    split_data = []

    # get_date_range returns a list
    totalrange = get_date_range(NUM_DAYS)
    # for value in list, run all of the following, replacing start_time and end_time for each value
    for subrange in range(0, len(totalrange)):
        start_time, end_time = totalrange[subrange]
        data_string = get_tweet_data(session, ANALYTICS_ACCOUNT, start_time, end_time, user_agent)

        if (subrange > 0):
            split_data = split_data + format_data(data_string)[1:]
            #print(split_data)
        else:
            split_data = split_data + format_data(data_string)
            #print(split_data)

    outfile = get_filename(OUTPUT_DIRECTORY, USERNAME)#, start_time, end_time)

    with open(outfile, 'w', encoding='utf-8') as f:
        writer = csv.writer(f)
        for line in split_data:
               writer.writerow(line)

    print("CSV downloaded: ", outfile)


def twitter_login(user, pw, user_agent):
    """Start a requests session and login to Twitter with credentials.
    Returned object is logged-in session."""

    tw_url = "https://twitter.com/"
    session = requests.session()
    first_req = session.get(tw_url)

    auth_token_str = re.search(r'<input type="hidden" value="([a-zA-Z0-9]*)" name="authenticity_token"\>',
          first_req.text)
    authenticity_token = auth_token_str.group(1)

    login_url = 'https://twitter.com/sessions'

    payload = {
        'session[username_or_email]' : user,
        'session[password]' : pw,
        'remember_me' : '1',
        'return_to_ssl' : 'true',
        'scribe_log' : None,
        'redirect_after_login':'/',
        'authenticity_token': authenticity_token
    }

    login_req = session.post(login_url, data=payload, headers=user_agent)
    #print( "login_req response: ", login_req.status_code)
    print('Logging into Twitter via SSH.')
    return session

def add_milliseconds(timestamp): # arbitrary since millisecond precision not necessary
        milli_ts = int(time.mktime(timestamp.timetuple()) * 1000)
        milli_ts = str(milli_ts)
        return milli_ts

def get_date_range(num_days):
    """Return date strings in UTC format. The data is returned as
    (start, end)
    with the end date being today and the begin date being 'num_days' prior.
    Twitter's maximum total days is 90."""

    date1 = datetime.datetime.utcnow()
    dateranges = []
    
    if num_days > 90:
        chunks = math.ceil(num_days/90)
        print('Breaking dates into into', chunks,'90 day chunks.')

        for chunk in range(1,chunks+1):
                date2 = date1 - datetime.timedelta(days=90)

                start = add_milliseconds(date1)
                end = add_milliseconds(date2)

                print('Chunk', chunk, ': ', date1, 'to', date2)
                dateranges.append((start,end))
                date1 = date2 - datetime.timedelta(days=1)
    
    else: 
        date1 = datetime.datetime.utcnow()
        date2 = date1 - datetime.timedelta(days=num_days)
        
        start = add_milliseconds(date1)
        end = add_milliseconds(date2)
        
        dateranges.append((start,end))
        
    return(dateranges)


def get_tweet_data(session, analytics_account, start_time, end_time, user_agent):
    """Complete the process behind clicking 'Export data' at
    https://analytics.twitter.com/user/USERNAME/tweets
    Data is returned as a raw string containing comma-separated data"""

    export_url = "https://analytics.twitter.com/user/" + analytics_account + "/tweets/export.json"
    bundle_url = "https://analytics.twitter.com/user/" + analytics_account + "/tweets/bundle"

    export_data = {
        'start_time' : end_time,
        'end_time' : start_time,
        'lang' : 'en'
    }
    querystring = '?' + urllib.parse.urlencode(export_data)
    print('Querying Twitter...')


    status = 'Pending'
    counter = 0
    while status == 'Pending':
        attempt = session.post(export_url + querystring, headers=user_agent)
        status_dict = json.loads(attempt.text)
        status = status_dict['status']
        counter += 1
        print('Attempt:', counter, ' Response:',status)
        time.sleep(5)

    csv_header = {'Content-Type': 'application/csv',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Encoding': 'gzip, deflate, sdch',
              'Accept-Language': 'en-US,en;q=0.8',
              'Upgrade-Insecure-Requests': '1',
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36'}

    data_req = session.get(bundle_url + querystring, headers=csv_header)
    #print("data_req response: ", data_req.status_code)
    print("Data retrieved, appending dataset.")
    return data_req.text


def format_data(data_string):
    """Transform raw data string into list-of-lists format"""
    lines = data_string.split('\"\n\"')
    split_data = [re.split(r"\"\s*,\s*\"", line) for line in lines]

    return split_data


def get_filename(output_dir, accountname):
    """Build descriptive filename for CSV"""
    f_name = 'twitter_data_' + accountname + str(datetime.datetime.utcnow()) + '.csv'#  start_time + '_' + end_time
    full_path = output_dir + '/' + f_name

    return full_path

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', help="Twitter handle for login", required=True)
    parser.add_argument('-p', help="Password", required=True)
    parser.add_argument('-d', help="Number of previous days' data to return (max: 90)", type=int, default=60)
    parser.add_argument('-o', help="Output directory", default=os.getcwd())
    parser.add_argument('-a', help="Account to return data for (default: -u)", required=False)
    args = parser.parse_args()

    USERNAME = args.u
    PASSWORD = args.p
    if args.a is not None: # default account for analytics is login account
        ANALYTICS_ACCOUNT = args.a
    else:
        ANALYTICS_ACCOUNT = USERNAME
    NUM_DAYS = args.d
    OUTPUT_DIRECTORY = args.o

    twitter_flow(USERNAME, PASSWORD, ANALYTICS_ACCOUNT, NUM_DAYS, OUTPUT_DIRECTORY)
