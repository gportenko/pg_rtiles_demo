#!/bin/bash

until psql 'postgresql://rtiles:rtiles@db:5432/rtiles' -c 'SELECT 1'; do
  echo 'Waiting for database to be ready...';
  sleep 1;
done &&
psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS hstore"
if ! psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "SELECT 1 FROM pg_namespace WHERE nspname = 'osm'" | grep -q 1; then
    echo initializing osm data... &&
    psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "CREATE SCHEMA osm" &&
    osm2pgsql -c -d rtiles -U rtiles -H db -P 5432 --output-pgsql-schema=osm --hstore dubai-coast.osm.pbf &&
    ogr2ogr -f PostgreSQL \
        "PG:host=db port=5432 dbname=rtiles user=rtiles" \
        land/dubai-coast-land.shp \
        -nln osm.land_polygons \
        -lco GEOMETRY_NAME=geom \
        -nlt PROMOTE_TO_MULTI \
        -lco FID=gid \
        -t_srs EPSG:3857 \
        -a_srs EPSG:3857 \
        -dim 2
fi
