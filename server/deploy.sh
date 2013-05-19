#!/bin/bash

# A deploy script for serving on somebits.com (with Nginx in front)
# Not really an example to emulate, but you're welcome to take a look.

cp -a server/serve.sh server/tilestache.cfg ~/rivers/
sed "s%127.0.0.1:8000%www.somebits.com:8000%" < server/gunicorn.cfg.py >| ~/rivers/gunicorn.cfg.py

cp -a clients/lib clients/forkme.png clients/us-states.js /var/www/rivers/
for c in clients/rivers-*.html; do
    sed 's%localhost:8000%www.somebits.com:8000%g' < $c >| /var/www/rivers/`basename $c`
done
