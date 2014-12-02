#!/bin/bash

# Launch a Gunicorn server to serve vector tiles

# Remove old cached files; not necessary, may be harmful in production
rm -rf /tmp/stache

# Launch gunicorn
gunicorn --error-logfile=- -c gunicorn.cfg.py 'TileStache:WSGITileServer("tilestache.cfg")'
