-- transform the geometry to spherical mercator
select AddGeometryColumn('nhdflowline', 'sphgeometry', 900913, 'MULTILINESTRING', 2);
update nhdflowline set sphgeometry = ST_Transform(geom, 900913);

-- create some indices on the important columns
create index nhdflowline_sphgeometry_gist on nhdflowline using gist(sphgeometry);
CREATE INDEX nhdflowline_comid_idx ON nhdflowline(comid);
CREATE INDEX plusflowlinevaa_comid_idx ON plusflowlinevaa(comid);

-- create a derived table that has the denormalized results for just our serving
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

-- indices on the served columns
create index rivers_geometry_gist on rivers using gist(geometry);

vacuum analyze nhdflowline;
vacuum analyze plusflowlinevaa;
vacuum analyze rivers;
