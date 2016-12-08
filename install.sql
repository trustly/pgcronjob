ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
CREATE TYPE public.batchjobstate AS ENUM (
    'AGAIN',
    'DONE'
);
COMMIT;
BEGIN;
DROP SCHEMA cron CASCADE;
COMMIT;
BEGIN;
\ir FUNCTIONS/pg_stat_activity_portable.sql
\ir cron.sql
COMMIT;
