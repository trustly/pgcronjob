ROLLBACK;
\set AUTOCOMMIT OFF
CREATE EXTENSION hstore;
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
\ir cron.sql
COMMIT;
