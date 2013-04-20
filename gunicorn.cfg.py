# Gunicorn configuration
# invoke: gunicorn -c gunicorn.cfg.py gunicorn -c gunicorn.cfg.py 'TileStache:WSGITileServer("tilestache.cfg")'

# Workaround for PYTHONPATH problem https://github.com/migurski/TileStache/issues/86
import sys
import PIL.Image
sys.modules['Image'] = PIL.Image

bind='127.0.0.1:8000'

workers=4
# worker_class='gevent'      # gevent seems slower, not necessary witha  proxy in front
