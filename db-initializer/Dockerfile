FROM ubuntu:22.04

RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
    lsb-release \
    curl \
    gnupg && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    apt reinstall ca-certificates -y && \
    update-ca-certificates && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg --yes && \
    apt update && \
    apt install -y --no-install-recommends \
    postgresql-client-16 \
    gdal-bin \
    osm2pgsql=1.6.0+ds-1 && \
    rm -rf /var/lib/apt/lists/*

COPY osm /osm
WORKDIR osm

RUN cat dubai-coast.osm.pbf.part* > dubai-coast.osm.pbf
    
