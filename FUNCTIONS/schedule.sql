CREATE OR REPLACE FUNCTION cron.Schedule(_Function regprocedure, _ProcessID integer DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
BEGIN

IF _ProcessID IS NULL THEN
    SELECT cron.Processes.ProcessID INTO _ProcessID FROM cron.Jobs
    INNER JOIN cron.Processes ON (cron.Processes.JobID = cron.Jobs.JobID)
    WHERE cron.Jobs.Function = _Function::text
    LIMIT 1;
END IF;

PERFORM pg_notify('cron.Dispatch()',_ProcessID::text);

RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Schedule(_Function regprocedure, _ProcessID integer) OWNER TO pgcronjob;
