<h1>Map of American Rivers</h1>
<h2>A vector tile demonstration and tutorial</h2>

This project contains everything you need from start to finish to make a vector-based web map of American rivers.
We start with downloading [shapefiles from NHDPlus](http://www.horizon-systems.com/nhdplus/) and
importing that data into [PostGIS](http://postgis.refractions.net/).
[TileStache](http://tilestache.org/) serves this geographic data up as
[GeoJSON](http://www.geojson.org/) vector tiles,
with help from [Gunicorn](http://gunicorn.org/) and [Nginx](http://nginx.org/). Finally the
vector tiles are presented as a web application with the usual slippy map, rendered by either
[Leaflet](http://leafletjs.com/) or [Polymaps](http://polymaps.org/). The vector river tiles are
drawn on top of raster basemaps provided by either [Stamen Design](http://maps.stamen.com/) or
[Esri](http://www.esri.com/data/basemaps).


It's a lot of pieces, but each one is simple in itself. Combined together
you have a powerful and flexible open source mapping stack. You're welcome to
[see the map running live]() on my server,
but the real point of this project is to show developers
all the pieces necessary to build their own map using vector tiles. Read on for details of how the map
is constructed, and be sure to [check out the source code]().

<h2>Quick start</h2>

* Install required software
* Run `downloadNhd.sh` to get data
* Run `importNhd.sh` to bring data into PostGIS
* Run `serve.sh` to start TileStache in Gunicorn
* Run `serverTest.py` to do a quick test on the server
* Load `slip-leaflet.html` to view the map

<h2>About vector tiles</h2>

Google Maps revolutioned online cartography by popularizing the use of
[map tiles](http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/) to serve
"slippy maps" with excellent quality and interactivity. Most slippy maps are raster maps, essentially
a mosaïc of PNG images glued together. But a lot of geographic data is intrinsically vector, lines
and polygons, and pre-rendering them into image tiles limits flexibility. Serving data as vector tiles
can result in maps that are faster, smaller, and more flexible.

Vector tiles are starting to catch on in proprietary applications; most mobile maps, for instance, are
now rendered with vector data. But doing vector mapping in the open source world is still a bit obscure.
The [Polymaps](http://polymaps.org/) Javascript library was an early pioneer in rendering vector tiles
but that capability has been unexplored, in part because generating vector tiles was difficult. But
vector tile servers are starting to become more common. This tutorial relies on
[TileStache's VecTiles provider](http://tilestache.org/doc/TileStache.Goodies.VecTiles.html).

Vector tiles are hard-mode for vector maps. If the full dataset is small it
is reasonable to serve the entire vector geometry as a single [GeoJSON](http://www.geojson.org/) file
and let the client library take care of clipping. That works fine for 100k of data but is impractical
with 10+M of geometry. Cropping to tiles optimizes sending only visible geometry. Scaling tiles enables
data to be simplified and down-sampled to match pixel visibility.

Vector tiles are ultimately quite simple: take a look at [this tile near near Oakland](http://127.0.0.1:8000/riverst/13/1316/3169.json). The [URL naming system](http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/) is exactly like Google's convention
for raster map tiles: zoom/y/x. Only instead of serving a PNG image what comes back instead is a
[GeoJSON file](http://www.geojson.org/) describing the geometry inside that region. This example has
6 features in it, each describing part of a river or creek. Each feature contains a geometry, a name,
and a [Strahler number](http://en.wikipedia.org/wiki/Strahler_Stream_Order) encoding the stream's
approximate size or importance. The only tricky thing about vector tiles is what to do about features that
cross tiles. In this tutorial we clip the geometry to the tile boundary and rely on the overlapping lines
being drawn to make a seamless map. It's also possible to not clip, which results in redundant data but
keeps features intact.

<h2>Required server software</h2>

The following is a partial list of software you need installed on your Mac or Linux system to generate
and serve these maps. (Sorry, Windows users; a Unix machine is a better choice for this kind of work.) On the Mac,
most prerequisites are available via [Homebrew](http://mxcl.github.io/homebrew/). On Ubuntu they are
available via `apt-get`, although the more recent versions from the [UbuntuGIS PPA](https://wiki.ubuntu.com/UbuntuGIS) are  recommended. Other Linux distributions can probably install the required software via the usual package system.
In general I prefer to install Python code with [pip](http://www.pip-installer.org/en/latest/) rather
than rely on the Mac or Ubuntu package versions.

* [curl](http://curl.haxx.se/) for downloading NHDPlus data from the web.
* [p7zip](http://p7zip.sourceforge.net/) for unpacking NHDPlus data. Ubuntu users be sure to install `p7zip-full`.
* [PostgreSQL](http://www.postgresql.org/) and [PostGIS](http://postgis.refractions.net/) for a geospatial database.
* `shp2pgsql`, part of PostGIS, for importing ESRI shapefiles into PostGIS
* [pgdbf](https://github.com/kstrauser/pgdbf) for importing DBF databases into PostgreSQL. Unfortunately the Ubuntu/precise
version 0.5.5 does not have the `-s` flag needed for handling non-ASCII data. Install from
[sources](http://sourceforge.net/projects/pgdbf/files/pgdbf/) or insure you're
getting version 0.6.* from somewhere.
* [gunicorn](http://gunicorn.org/) for a Python web app server.
* [nginx](http://nginx.org/) for a front-end web proxy to talk to the outside world. Not strictly necessary,
but Gunicorn is designed with a front-end in mind.
* [TileStache](http://tilestache.org/) for the Python web app that serves map tiles. TileStache has
undocumented dependencies on [Shapely](https://pypi.python.org/pypi/Shapely) and
[psycopg2](http://initd.org/psycopg/).
* [requests](http://docs.python-requests.org/en/latest/) and [grequests](https://github.com/kennethreitz/grequests) for `serverTest.py`, a Python HTTP client test.
* [gdal](http://www.gdal.org/) is the low level library for open source geo. The parts you need will be installed
as dependencies by the tools above, listing it here for proper respect.


<h2>Map components</h2>

