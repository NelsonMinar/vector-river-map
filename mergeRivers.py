#!/usr/bin/env python

"""Merge river records from NHDPlus based on gnis_id.
NHDPlus breaks a river up into lots of separate little LineStrings,
separate rows in the database. This makes for inefficient queries
and GeoJSON, so we merge them here."""

import psycopg2
import time

conn = psycopg2.connect("dbname=rivers host=localhost")
conn.autocommit = True      # required for Postgres bug workaround below
cur = conn.cursor()

start = time.time()

def log(msg):
    "Log a message with some reporting on time elapsed"
    print "{:>7.2f}s {}".format(time.time()-start, msg)

# Create the schema
cur.execute("""drop table if exists merged_rivers;""")
cur.execute("""
create table merged_rivers (
    gnis_id integer,
    name text,
    huc8 text,
    strahler smallint,
    geometry geometry);
""")
log("Table created")

# Figure out how many different HUC8s we're dealing with
cur.execute("select count(distinct(huc8)) from rivers;")
count = cur.fetchone()[0]
log("Processing {} unique HUC8s".format(count))

# Need a separate cursor for inserts
insertCursor = conn.cursor()

# Iterate through each unique HUC8. For each one, create
# one row in merged_rivers for each unique (gnis_id, strahler)
# pair. gnis_id is often null, so sometimes we'll be throwing
# together unrelated rivers, but at least they're nearby.
 # In theory this could all be done with one grand
#   create table from select...
# but in practice PostGIS didn't seem to do well with that.

cur.execute("select distinct(huc8) from rivers;")
for (huc8,) in cur:
    # Willing to try each insert twice; working around a bug in Postgres
    tries = 2
    success = False
    while tries > 0 and not success:
        tries -= 1
        try:
            insertCursor.execute("""
                insert into merged_rivers(gnis_id, name, strahler, huc8, geometry)
                select
                    MAX(gnis_id) as gnis_id,
                    MAX(name) as name,
                    MAX(strahler),
                    MAX(huc8) as huc8,
                    ST_LineMerge(ST_Union(geometry)) as geometry
                from rivers
                where huc8 = %s
                group by (gnis_id,strahler)""", (huc8,))
            success = True
        except psycopg2.InternalError as e:
            # Work around Postgres bug #8167 on MacOS. Details at
            # https://gist.github.com/NelsonMinar/5588719
            if str(e).strip().endswith("Invalid argument"):
                log("Transient error, trying insert again. Tries left: {}".format(tries))
            else:
                raise e;

    # Partial status report
    count -= 1
    if (count % 100 == 0):
        log("{:5} HUC8s to go {:5} rows added for huc8 {}".format(count, insertCursor.rowcount, huc8))

# Commit the new table
conn.commit()

# Build some indices
log("Creating indices")
insertCursor.execute("create index merged_rivers_geometry_gist on merged_rivers using gist(geometry);")
insertCursor.execute("create index merged_rivers_strahler_idx ON merged_rivers(strahler);")
conn.commit()

# Can't vacuum in a transaction
conn.autocommit = True
insertCursor.execute("vacuum analyze merged_rivers;")

log("All done!")
