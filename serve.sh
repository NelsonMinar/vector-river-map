#!/bin/bash
gunicorn -c gunicorn.cfg.py 'TileStache:WSGITileServer("tilestache.cfg")'
