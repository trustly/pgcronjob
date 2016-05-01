CREATE OR REPLACE FUNCTION cron.Is_Valid_Function(_Function regprocedure)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO public, pg_temp
AS $FUNC$
SELECT TRUE FROM pg_catalog.pg_proc
-- All functions registered in Jobs must return BATCHJOBSTATE which is just an ENUM 'AGAIN' or 'DONE',
-- to indicate whether or not cron.Run() should run the function again or if the job is done.
-- This is to avoid accidents and to force the user to be explicit about what to do,
-- instead of using a plain boolean as return value, which could be misinterpreted.
WHERE oid = $1::oid
AND prorettype::regtype::text = 'batchjobstate'
AND EXISTS (
    -- It's not enough to just register the function using cron.Register().
    -- The user must also explicitly grant execute on the function to the pgcronjob role,
    -- using the command: GRANT EXECUTE ON FUNCTION ... TO pgcronjob.
    -- This is to reduce the risk of accidents from happening, in case of human errors.
    SELECT 1 FROM aclexplode(pg_catalog.pg_proc.proacl)
    WHERE aclexplode.privilege_type = 'EXECUTE'
    AND aclexplode.grantee = (
        SELECT pg_catalog.pg_user.usesysid FROM pg_catalog.pg_user
        WHERE pg_catalog.pg_user.usename = 'pgcronjob'
    )
)
$FUNC$;

ALTER FUNCTION cron.Is_Valid_Function(_Function regprocedure) OWNER TO pgcronjob;
