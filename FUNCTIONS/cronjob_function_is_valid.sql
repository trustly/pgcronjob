CREATE OR REPLACE FUNCTION public.CronJob_Function_Is_Valid(
_SchemaName   text,
_FunctionName text
)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO public, pg_temp
AS $FUNC$
SELECT TRUE FROM pg_catalog.pg_proc
INNER JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_proc.pronamespace)
-- All functions registered in CronJobs must return BATCHJOBSTATE which is just an ENUM 'AGAIN' or 'DONE',
-- to indicate whether or not CronJob() should run the function again or if the job is done.
-- This is to avoid accidents and to force the user to be explicit about what to do,
-- instead of using a plain boolean as return value, which could be misinterpreted.
WHERE pg_catalog.pg_namespace.nspname = $1
AND pg_catalog.pg_proc.proname = $2
AND pg_catalog.pg_proc.prorettype::regtype::text = 'batchjobstate'
AND EXISTS (
    -- It's not enough to just register the function using Register_CronJob().
    -- The user must also explicitly grant execute on the function to the pgcronjob role,
    -- using the command: GRANT EXECUTE ON FUNCTION [SchemaName].[FunctionName] TO pgcronjob.
    -- This is to reduce the risk of accidents from happening, in case of human errors.
    SELECT 1 FROM aclexplode(pg_catalog.pg_proc.proacl)
    WHERE aclexplode.privilege_type = 'EXECUTE'
    AND aclexplode.grantee = (
        SELECT pg_catalog.pg_user.usesysid FROM pg_catalog.pg_user
        WHERE pg_catalog.pg_user.usename = 'pgcronjob'
    )
)
$FUNC$;
