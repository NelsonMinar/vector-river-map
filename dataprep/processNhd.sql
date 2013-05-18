-- Create a derived table that has the denormalized results for just our serving
-- PostGIS 9.1 is smart enough to set up the spatial column metadata for us
create table rivers as
  select
    -- unique ID for individual segments of a river; used by nhdflowline
    cast(nhdflowline.comid as integer) as comid,
    -- ID for a whole river. Ie: Mississippi = 1629903. Can be null.
    cast(gnis_id as integer) as gnis_id,
    -- name for a river (may be empty)
    gnis_name as name,
    -- HUC8 names the watershed this flow is part of
    substring(plusflowlinevaa.reachcode from 1 for 8) as huc8,
    -- Strahler number, measure of the significance of a river
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
create index rivers_huc8_idx on rivers(huc8);

-- analyze to give the query planner appropriate hints
vacuum analyze rivers;

-- we could drop these tables, but it's nice to leave them around
-- drop table nhdflowline;
-- drop table plusflowlinevaa;
