#!/bin/bash

# Load the Flowlines database into PostGIS
# See also https://gist.github.com/mojodna/b1f169b33db907f2b8dd

set -eu

DB=rivers
export DYLD_FALLBACK_LIBRARY_PATH=/usr/homebrew/lib

shp=/Users/nelson/geodata/NHD/NHDPlusCA/NHDPlus18/NHDSnapshot/Hydrography/NHDFlowline.shp
vaa=/Users/nelson/geodata/NHD/NHDPlusCA/NHDPlusAttributes/PlusFlowlineVAA.dbf

# Create a PostGIS database
createdb $DB
psql -d $DB -c 'create extension postgis'
psql -d $DB -c 'create extension postgis_topology'

# Import data tables from NHD
shp2pgsql -t 2d -s 4269 -I -D -W LATIN1 "$shp" | pv | psql -d $DB -q
pgdbf -s LATIN1 "$vaa" | psql -d $DB -q

# Run our script

psql -d $DB -f processNhd.sql
