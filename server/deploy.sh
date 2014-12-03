#!/bin/bash

# A deploy script for serving on somebits.com (with Nginx in front)
# Not really an example to emulate, but you're welcome to take a look.

# Server code
cp -a server/serve.sh server/tilestache.cfg server/gunicorn.cfg.py ~/rivers/

# Client code
cp -a clients/lib clients/forkme.png clients/us-states.js /var/www/somebits/rivers/
for c in clients/rivers-*.html; do
    sed 's%localhost:8000%www.somebits.com:8001%g' < $c >| /var/www/somebits/rivers/`basename $c`
done

# Check nginx config
cmp -s server/nginx-rivers.conf /etc/nginx/sites-enabled/rivers
if [ $? -ne 0 ]; then
    echo "Warning: server/nginx-rivers.conf is out of sync"
    diff -u /etc/nginx/sites-enabled/rivers server/nginx-rivers.conf
fi

# Warning
echo "There is no init script. Have to start from ~/rivers/ manually."
