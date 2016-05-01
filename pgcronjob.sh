#!/bin/bash

set -e
set -u

# Set these environmental variables to override them
export PGHOST=${PGHOST-}
export PGPORT=${PGPORT-}
export PGDATABASE=${PGDATABASE-}
export PGUSER=${PGUSER-pgcronjob}
export PGPASSWORD=${PGPASSWORD-}

BATCHJOBSTATE="AGAIN"
while [ "$BATCHJOBSTATE" = "AGAIN" ]; do
    BATCHJOBSTATE=$(PGOPTIONS='--client-min-messages=error' psql -A -t -X -L pgcronjob.log -c "SELECT cron.Run()")
    echo $BATCHJOBSTATE
done
