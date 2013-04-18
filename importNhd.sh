#!/bin/bash

# Load the Flowlines database into PostGIS
# See also https://gist.github.com/mojodna/b1f169b33db907f2b8dd

set -eu

DB=rivers
export DYLD_FALLBACK_LIBRARY_PATH=/usr/homebrew/lib

shp=/Users/nelson/geodata/NHD/NHDPlusCA/NHDPlus18/NHDSnapshot/Hydrography/NHDFlowline.shp
vaa=/Users/nelson/geodata/NHD/NHDPlusCA/NHDPlusAttributes/PlusFlowlineVAA.dbf

# Database
createdb $DB
psql -d $DB -c 'create extension postgis'
psql -d $DB -c 'create extension postgis_topology'

# Flowlines
shp2pgsql -t 2d -s 4269 -I -D -W LATIN1 "$shp" | pv | psql -d $DB -q
psql -d $DB -c "select AddGeometryColumn('nhdflowline', 'sphgeometry', 900913, 'MULTILINESTRING', 2);"
psql -d $DB -c "update nhdflowline set sphgeometry = ST_Transform(geom, 900913);"

# Value added attributes
pgdbf -s LATIN1 "$vaa" | psql -d $DB -q

# Indices
# nhdflowline.geom already has an index thanks to the import command
psql -q -d $DB -c "create index nhdflowline_sphgeometry_gist on nhdflowline using gist(sphgeometry);"
psql -q -d $DB -c "CREATE INDEX nhdflowline_comid_idx ON nhdflowline(comid);"
psql -q -d $DB -c "CREATE INDEX plusflowlinevaa_comid_idx ON plusflowlinevaa(comid);"
psql -q -d $DB -c "vacuum analyze nhdflowline"
psql -q -d $DB -c "vacuum analyze plusflowlinevaa"
