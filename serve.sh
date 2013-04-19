#!/bin/bash
rm -rf /tmp/stache
gunicorn -c gunicorn.cfg.py 'TileStache:WSGITileServer("tilestache.cfg")'
