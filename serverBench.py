#!/usr/bin/env python

import requests, time

urlbase = 'http://127.0.0.1:8000'
url = 'riverst/8/41/98.json'

start = time.time()
r = requests.get("{}/{}".format(urlbase, url))
end = time.time()
print("Request took {:.0f} ms".format(1000 * (end-start)))
assert r.status_code == 200

j = r.json()
assert j["type"] == "FeatureCollection"
assert len(j["features"]) == 1285
assert j["features"][0]["geometry"]["coordinates"][0][0] == -121.721604
