#!/bin/bash

set -e
set -u

# Set these environmental variables to override them
export PGHOST=${PGHOST-localhost}
export PGPORT=${PGPORT-5432}
export PGDATABASE=${PGDATABASE-$USER}
export PGUSER=${PGUSER-pgcronjob}
export PGPASSWORD=${PGPASSWORD-my_password}

BATCHJOBSTATE="AGAIN"
while [ "$BATCHJOBSTATE" = "AGAIN" ]; do
    BATCHJOBSTATE=$(PGOPTIONS='--client-min-messages=error' psql -A -t -X -L pgcronjob.log -c "SELECT CronJob()")
    echo $BATCHJOBSTATE
done
