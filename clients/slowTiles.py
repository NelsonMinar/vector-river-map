#!/usr/bin/env python

"""Test times and sizes of some particularly large or difficult tiles."""

import requests, time, grequests

urlbase = 'http://127.0.0.1:8000'
for spot in ('7/25/49', '6/13/23', '5/6/11', '5/7/12', '4/3/6'):
    url = "{}/rivers/{}.json".format(urlbase, spot);
    start = time.time()
    r = requests.get(url)
    l = len(r.content);
    end = time.time()
    j = r.json()

    assert r.status_code == 200
    print "{:>8}: {:6.0f} ms {:6.0f} kb {:>6} features".format(spot, 1000*(end-start), l/1024, len(j['features']))
