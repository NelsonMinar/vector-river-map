#!/usr/bin/python
import os, TileStache
TileStache.cgiHandler(os.environ, 'tilestache.cfg', debug=False)
