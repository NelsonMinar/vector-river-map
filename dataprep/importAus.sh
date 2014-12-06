#!/bin/bash

# Import Australian stream data into Postgres
# http://www.bom.gov.au/water/geofabric/

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
DATADIR=/Users/nelson/Downloads/SH_Cartography_GDB
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

### Import river table
sourceData="$DATADIR/SH_Cartography.gdb"

ogr2ogr -f "PostgreSQL" PG:"dbname=$DB" \
    "$sourceData" ahgfmappedstream \
    -a_srs EPSG:4283 \
    -progress --config PG_USE_COPY YES

# ogr2ogr creates a spatial index automatically

psql -d "$DB" -c 'create index  ahgfmappedstream_perennial_idx on ahgfmappedstream(perennial);'
psql -d "$DB" -c 'create index ahgfmappedstream_upstrgeoln_idx on ahgfmappedstream(upstrgeoln);'

### clean up and analyze
psql -d "$DB" -c 'vacuum analyze' > /dev/null

### And print some stats
end=`date +%s`
echo -n "Size of table: "
psql -t -d $DB -c "select pg_size_pretty(pg_total_relation_size('ahgfmappedstream'));"  | head -1
echo "Total time:" $[end-start] "seconds"
