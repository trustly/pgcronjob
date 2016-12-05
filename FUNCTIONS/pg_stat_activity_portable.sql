CREATE OR REPLACE FUNCTION public.pg_stat_activity_portable()
RETURNS TABLE (
    datid               oid,
    datname             name,
    pid                 integer,
    usesysid            oid,
    usename             name,
    application_name    text,
    client_addr         inet,
    client_hostname     text,
    client_port         integer,
    backend_start       timestamp with time zone,
    xact_start          timestamp with time zone,
    query_start         timestamp with time zone,
    waiting             boolean,
    state               text,
    query               text
)
AS $$
-- This function exposes the 9.2-compatible interface on versions 9.1 and later.
DECLARE
_VersionNum int;
BEGIN

_VersionNum := current_setting('server_version_num')::int;
IF  _VersionNum >= 90600 THEN
    RETURN QUERY
    SELECT
        s.datid,
        s.datname,
        s.pid,
        s.usesysid,
        s.usename,
        s.application_name,
        s.client_addr,
        s.client_hostname,
        s.client_port,
        s.backend_start,
        s.xact_start,
        s.query_start,
        s.wait_event IS NOT NULL AS waiting,
        s.state,
        s.query
    FROM pg_stat_activity s;
ELSIF _VersionNum >= 90200 THEN
    RETURN QUERY
    SELECT
        s.datid,
        s.datname,
        s.pid,
        s.usesysid,
        s.usename,
        s.application_name,
        s.client_addr,
        s.client_hostname,
        s.client_port,
        s.backend_start,
        s.xact_start,
        s.query_start,
        s.waiting,
        s.query
    FROM pg_stat_activity s;
ELSE
    RETURN QUERY
    SELECT
        s.datid,
        s.datname,
        s.procpid,
        s.usesysid,
        s.usename,
        s.application_name,
        s.client_addr,
        s.client_hostname,
        s.client_port,
        s.backend_start,
        s.xact_start,
        s.query_start,
        s.waiting,
        CASE WHEN s.current_query = '<IDLE> in transaction' THEN text 'idle in transaction'
             WHEN s.current_query = '<IDLE>' THEN text 'idle'
             WHEN s.current_query = '<IDLE> in transaction (aborted)' THEN text 'idle in transaction (aborted)'
             WHEN s.current_query = '<insufficient privilege>' THEN NULL::text
             ELSE text 'active'
            END AS state,
        s.current_query
    FROM pg_stat_activity s;
END IF;
END
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.pg_stat_activity_portable() OWNER TO pgterminator;
