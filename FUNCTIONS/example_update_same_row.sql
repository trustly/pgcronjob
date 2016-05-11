CREATE TABLE cron.ExampleUpdateSameRow (ID int NOT NULL PRIMARY KEY, Datestamp timestamptz, ProcessID integer);
INSERT INTO cron.ExampleUpdateSameRow (ID) VALUES (1);

CREATE OR REPLACE FUNCTION cron.Example_Update_Same_Row(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.ExampleUpdateSameRow SET Datestamp = clock_timestamp(), ProcessID = _ProcessID WHERE ID = 1;
PERFORM pg_sleep(random());
IF random() < 0.01 THEN
    RETURN 'DONE';
ELSE
    RETURN 'AGAIN';
END IF;
END;
$FUNC$;

ALTER FUNCTION cron.Example_Update_Same_Row(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Example_Update_Same_Row(_ProcessID integer) TO pgcronjob;
