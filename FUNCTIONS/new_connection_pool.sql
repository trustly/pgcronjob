CREATE OR REPLACE FUNCTION cron.New_Connection_Pool(_Name text, _MaxProcesses integer)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_ConnectionPoolID integer;
BEGIN

INSERT INTO cron.ConnectionPools ( Name, MaxProcesses)
VALUES                           (_Name,_MaxProcesses)
RETURNING ConnectionPoolID INTO STRICT _ConnectionPoolID;

RETURN _ConnectionPoolID;
END;
$FUNC$;

ALTER FUNCTION cron.New_Connection_Pool(_Name text, _MaxProcesses integer) OWNER TO pgcronjob;
