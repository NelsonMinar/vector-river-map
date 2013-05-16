#!/bin/bash

# Load the Flowlines databases into PostGIS
# See also https://gist.github.com/mojodna/b1f169b33db907f2b8dd

### Workaround for a bug with a non-standard Homebrew install
### https://github.com/mxcl/homebrew/issues/19213
if type brew > /dev/null 2>&1; then
    BREWDIR=`brew --prefix`
    if [ "$BREWDIR" != "/usr/local" ]; then
        export DYLD_FALLBACK_LIBRARY_PATH="$BREWDIR/lib"
    fi
fi

### Defensive shell scripting
set -eu

### Configurable variables
DATADIR=./NHD
DB=rivers

### Set up logging
LOG=`mktemp /tmp/nhd.log.XXXXXX`
echo "Script output logging to $LOG"

### Simple time statistic
start=`date +%s`

### Create a PostGIS database
FAIL=0; createdb $DB || FAIL=1 && true
if [ "$FAIL" -ne 0 ]; then
    echo "You need to 'dropdb $DB' for this script to run"
    exit
fi
psql -q -d $DB -c 'create extension postgis'
psql -q -d $DB -c 'create extension postgis_topology'

### Import NHDFlowline tables
# Find the data files
flowlines="$DATADIR/NHDPlus??/NHDPlus*/NHDSnapshot/Hydrography/NHDFlowline.shp"

# Create the schema based on the first file
set -- $flowlines
echo "Creating nhdflowline schema"
(shp2pgsql -p -D -t 2d -s 4269 -W LATIN1 "$1" | psql -d $DB -q) >> $LOG 2>&1

# Import the files
for flowline in $flowlines; do
    echo "Importing $flowline"
    (shp2pgsql -a -D -t 2d -s 4269 -W LATIN1 "$flowline" | psql -d $DB -q) >> $LOG 2>&1
done

### Import PlusFlowlineVAA
# Find the data files
vaas="$DATADIR/NHDPlus??/NHDPlus*/NHDPlusAttributes/PlusFlowlineVAA.dbf"

# Create the schema based on the first file
set -- $vaas
echo "Creating plusflowlinevaa schema"
(pgdbf -D -s LATIN1 "$1" | psql -d $DB -q) >> $LOG 2>&1
psql -d $DB -c "TRUNCATE TABLE plusflowlinevaa;" >> $LOG 2>&1

# Import the files
for vaa in $vaas; do
    echo "Importing $vaa"
    (pgdbf -CD -s LATIN1 "$vaa" | psql -d $DB -q) >> $LOG 2>&1
done

### Run a SQL script to clean up the database and building indices
echo "Building rivers table from downloaded files"
psql -d $DB -f processNhd.sql >> $LOG 2>&1

### Run a Python script to merge rivers for serving
echo "Creating the merged_rivers table from rivers"
python -u mergeRivers.py

### And print some stats
end=`date +%s`
echo -n "Size of rivers table: "
psql -t -d $DB -c "select pg_size_pretty(pg_total_relation_size('rivers'));"  | head -1
echo -n "Size of merged_rivers table: "
psql -t -d $DB -c "select pg_size_pretty(pg_total_relation_size('merged_rivers'));"  | head -1
echo "Total time:" $[end-start] "seconds"
