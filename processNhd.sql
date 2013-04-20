-- create a derived table that has the denormalized results for just our serving
-- Tilestache requires the geometry column be named 'geometry'
-- PostGIS 9.1 is smart enough to set up the spatial column metadata for us
create table rivers as
  select nhdflowline.comid,
         cast(streamorde as int8) as strahler,   -- TileStache doesn't do DECIMAL()
         gnis_name as name,
         ftype as ftype,
         ST_Transform(geom, 900913) as geometry  -- Spherical Mercator for web maps
  from nhdflowline, plusflowlinevaa
  where nhdflowline.comid = plusflowlinevaa.comid
    and nhdflowline.ftype != 'Coastline';

-- indices on our derived table
create index rivers_geometry_gist on rivers using gist(geometry);
create index rivers_strahler_idx ON rivers(strahler);

-- analyze to give the query planner appropriate hints
vacuum analyze rivers;

-- we could drop these tables, but it's nice to leave them around
-- drop table nhdflowline;
-- drop table plusflowlinevaa;
