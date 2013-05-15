#!/usr/bin/env python

"""Merge river records from NHDPlus based on gnis_id.
NHDPlus breaks a river up into lots of separate little LineStrings,
separate rows in the database. This makes for inefficient queries
and GeoJSON, so we merge them here."""

import psycopg2
import time

conn = psycopg2.connect("dbname=rivers host=localhost")
cur = conn.cursor()

start = time.time()

def log(msg):
    "Log a message with some reporting on time elapsed"
    print "{:>6.2f}s {}".format(time.time()-start, msg)

# Create the schema
cur.execute("""drop table if exists rivers4;""")
cur.execute("""
create table rivers4 (
    gnis_id integer,
    name varchar(65),
    strahler smallint,
    geometry geometry);
""")
log("Table created")

# Figure out how many different gnis_ids we're dealing with
cur.execute("select count(distinct(gnis_id)) from rivers;")
count = cur.fetchone()[0]

# Need a separate cursor for inserts
insertCursor = conn.cursor()

# Iterate through each unique gnis_id and create rows in
# our new database that are merged copies of that record
# In theory this could all be done with one grand
# create table from select...
# but in practice PostGIS didn't seem to do well with that.
cur.execute("select distinct(gnis_id) from rivers;")
for (gnisId,) in cur:
    insertCursor.execute("""
        insert into rivers4(gnis_id, name, strahler, geometry)
        select
            MAX(gnis_id) as gnis_id,
            MAX(name) as name,
            MAX(strahler) as strahler,
            ST_LineMerge(ST_Union(geometry)) as geometry
        from rivers
        where gnis_id = %s
        group by (gnis_id,strahler)""", (gnisId,))
    # Partial status report
    count -= 1
    if (count % 1000 == 0):
        log("{} to go {} rows added for gnis_id {}".format(count, insertCursor.rowcount, gnisId))

# Merging via gnis_is means we discard all rivers where gnis_id is null.
# That's a bug; it's a lot of rivers.
# We can simply copy them in, but it's a lot of bloat. Would be nice to merge.
# insert into rivers3(gnis_id, name, strahler, geometry) select  gnis_id, name, strahler, geometry from rivers where gnis_id is null;

# Commit the new table
conn.commit()

# Build some indices
log("Creating indices")
insertCursor.execute("create index rivers4_geometry_gist on rivers4 using gist(geometry);")
insertCursor.execute("create index rivers4_strahler_idx ON rivers4(strahler);")
conn.commit()

# Can't vacuum in a transaction
conn.set_isolation_level(0)
insertCursor.execute("vacuum analyze rivers4;")

log("All done!")
