#!/usr/bin/env python
# Workaround for PYTHONPATH problem https://github.com/migurski/TileStache/issues/86
import sys
import PIL.Image
sys.modules['Image'] = PIL.Image

import os, TileStache
TileStache.cgiHandler(os.environ, 'tilestache.cfg', debug=False)
