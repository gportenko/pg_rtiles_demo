#!/bin/bash

if ! psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "SELECT 1 FROM pg_extension where extname = 'rtiles'" | grep -q 1; then
    echo initializing rtiles... &&
    psql "postgresql://rtiles:rtiles@db:5432/rtiles" -c "CREATE EXTENSION rtiles" &&
    psql "postgresql://rtiles:rtiles@db:5432/rtiles" -a -f /scripts/init-rtiles.sql
fi
