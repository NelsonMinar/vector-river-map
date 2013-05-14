-- Create a derived table that has the denormalized results for just our serving
-- PostGIS 9.1 is smart enough to set up the spatial column metadata for us
create table rivers as
  select
    -- unique ID for individual segments of a river. Could be a primary key.
    cast(nhdflowline.comid as integer) as comid,
    -- unique ID for a whole river. Ie: Mississippi = 1629903
    cast(nhdflowline.gnis_id as integer) as gnis_id,
    -- name for a river (may be empty)
    gnis_name as name,
    -- Strahler number, measure of the singificance of a river
    cast(streamorde as smallint) as strahler,
    -- river geometry; convert to spherical mercator since we're doing web maps
    ST_Transform(geom, 900913) as geometry
  from nhdflowline, plusflowlinevaa
  where nhdflowline.comid = plusflowlinevaa.comid
    and nhdflowline.ftype != 'Coastline';

-- indices on our derived table
create index rivers_geometry_gist on rivers using gist(geometry);
create index rivers_strahler_idx ON rivers(strahler);
create index rivers_gnis_id_idx on rivers(gnis_id);

-- analyze to give the query planner appropriate hints
vacuum analyze rivers;

-- we could drop these tables, but it's nice to leave them around
-- drop table nhdflowline;
-- drop table plusflowlinevaa;
