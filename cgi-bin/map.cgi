#!/usr/bin/env python
# Workaround for PYTHONPATH problem https://github.com/migurski/TileStache/issues/86
import sys
import PIL.Image
sys.modules['Image'] = PIL.Image

import os, TileStache

# Find config file; path varies depending on CGI environment
for fn in ['tilestache.cfg', '../tilestache.cfg']:
    if os.path.exists(fn):
        break
TileStache.cgiHandler(os.environ, fn, debug=False)
