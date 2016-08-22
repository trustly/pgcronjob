CREATE OR REPLACE FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_LogWaitingID integer;
_NeverSeenBefore boolean;
_DumpPgStatActivity boolean;
BEGIN

_NeverSeenBefore := NOT EXISTS (SELECT 1 FROM cron.LogWaiting WHERE NumPIDs = _NumPIDs AND MaxSeconds = _MaxSeconds);
INSERT INTO cron.LogWaiting (NumPIDs, MaxSeconds) VALUES (_NumPIDs, _MaxSeconds) RETURNING LogWaitingID INTO STRICT _LogWaitingID;
IF _NeverSeenBefore THEN
    IF (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN
        INSERT INTO cron.LogWaitingPgStatActivity (
            LogWaitingID,
            datid,
            datname,
            procpid,
            usesysid,
            usename,
            application_name,
            client_addr,
            client_hostname,
            client_port,
            backend_start,
            xact_start,
            query_start,
            waiting,
            current_query
        )
        SELECT
            _LogWaitingID,
            datid,
            datname,
            procpid,
            usesysid,
            usename,
            application_name,
            client_addr,
            client_hostname,
            client_port,
            backend_start,
            xact_start,
            query_start,
            waiting,
            current_query
        FROM pg_stat_activity;
    ELSE
        INSERT INTO cron.LogWaitingPgStatActivity (
            LogWaitingID,
            datid,
            datname,
            procpid,
            usesysid,
            usename,
            application_name,
            client_addr,
            client_hostname,
            client_port,
            backend_start,
            xact_start,
            query_start,
            waiting,
            current_query
        )
        SELECT
            _LogWaitingID,
            datid,
            datname,
            pid,
            usesysid,
            usename,
            application_name,
            client_addr,
            client_hostname,
            client_port,
            backend_start,
            xact_start,
            query_start,
            waiting,
            current_query
        FROM pg_stat_activity;
    END IF;
END IF;

RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) OWNER TO sudo;

REVOKE ALL ON FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) FROM PUBLIC;
GRANT  ALL ON FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) TO pgcronjob;
