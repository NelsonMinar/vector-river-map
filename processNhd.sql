-- transform the geometry to spherical mercator
select AddGeometryColumn('nhdflowline', 'sphgeometry', 900913, 'MULTILINESTRING', 2);
update nhdflowline set sphgeometry = ST_Transform(geom, 900913);

-- create some indices on the important columns
create index nhdflowline_sphgeometry_gist on nhdflowline using gist(sphgeometry);
create index nhdflowline_comid_idx ON nhdflowline(comid);
create index plusflowlinevaa_comid_idx ON plusflowlinevaa(comid);

-- create a derived table that has the denormalized results for just our serving
-- PostGIS is smart enough to set up the spatial column
create table rivers as
  select gid,
         nhdflowline.comid,
         cast(streamorde as int8) as strahler,
         gnis_name as name,
         ftype as ftype,
         sphgeometry as geometry
  from nhdflowline, plusflowlinevaa
  where nhdflowline.comid = plusflowlinevaa.comid
    and nhdflowline.ftype != 'Coastline';

alter table rivers add primary key (gid);

-- spatial index on the served column
create index rivers_geometry_gist on rivers using gist(geometry);

-- analyze to give the query planner appropriate hints
vacuum analyze nhdflowline;
vacuum analyze plusflowlinevaa;
vacuum analyze rivers;
