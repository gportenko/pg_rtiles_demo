#!/bin/bash

if ! psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "SELECT 1 FROM pg_namespace WHERE nspname = 'map_layers'" | grep -q 1; then
    echo initializing map layers... &&
    psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "CREATE EXTENSION IF NOT EXISTS pg_cron" &&
    psql "postgresql://rtiles:rtiles@db:5432/rtiles" -a -f /scripts/init-map-layers.sql
fi
