#!/bin/bash

# Load the Flowlines database into PostGIS
# See also https://gist.github.com/mojodna/b1f169b33db907f2b8dd

set -eu

export DYLD_FALLBACK_LIBRARY_PATH=/usr/homebrew/lib

shp=/Volumes/nelson/geodata/NHD/NHDPlusCA/NHDPlus18/NHDSnapshot/Hydrography/NHDFlowline.shp
vaa=/Volumes/nelson/geodata/NHD/NHDPlusCA/NHDPlusAttributes/PlusFlowlineVAA.dbf

# Database
createdb nhd
psql -d nhd -c 'create extension postgis'
psql -d nhd -c 'create extension postgis_topology'

# Flowlines
shp2pgsql -t 2d -s 4269 -I -D -W LATIN1 "$shp" | pv | psql -d nhd -q
psql -d nhd -c "select AddGeometryColumn('nhdflowline', 'sphgeometry', 900913, 'MULTILINESTRING', 2);"
psql -d nhd -c "update nhdflowline set sphgeometry = ST_Transform(geom, 900913);"

# Value added attributes
pgdbf -s LATIN1 "$vaa" | psql -d nhd -q

# Indices
# nhdflowline.geom already has an index thanks to the import command
psql -q -d nhd -c "create index nhdflowline_sphgeometry_gist on nhdflowline using gist(sphgeometry);"
psql -q -d nhd -c "CREATE INDEX nhdflowline_comid_idx ON nhdflowline(comid);"
psql -q -d nhd -c "CREATE INDEX plusflowlinevaa_comid_idx ON plusflowlinevaa(comid);"
psql -q -d nhd -c "vacuum analyze nhdflowline"
psql -q -d nhd -c "vacuum analyze plusflowlinevaa"
