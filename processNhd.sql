-- create some indices on the important columns
create index nhdflowline_comid_idx ON nhdflowline(comid);
create index plusflowlinevaa_comid_idx ON plusflowlinevaa(comid);

-- create a derived table that has the denormalized results for just our serving
-- Tilestache requires the geometry column be named 'geometry'
-- PostGIS is smart enough to set up the spatial column metadata with this command
create table rivers as
  select gid,
         nhdflowline.comid,
         cast(streamorde as int8) as strahler,
         gnis_name as name,
         ftype as ftype,
         ST_Transform(geom, 900913) as geometry
  from nhdflowline, plusflowlinevaa
  where nhdflowline.comid = plusflowlinevaa.comid
    and nhdflowline.ftype != 'Coastline';

alter table rivers add primary key (gid);

-- indices on our derived table
create index rivers_geometry_gist on rivers using gist(geometry);
create index rivers_comid_idx ON rivers(comid);

-- analyze to give the query planner appropriate hints
vacuum analyze nhdflowline;
vacuum analyze plusflowlinevaa;
vacuum analyze rivers;
