CREATE TABLE cron.LogWaitingPgStatActivity (
LogWaitingPgStatActivityID serial NOT NULL,
LogWaitingID               integer NOT NULL,
datid                      oid,
datname                    name,
procpid                    integer,
usesysid                   oid,
usename                    name,
application_name           text,
client_addr                inet,
client_hostname            text,
client_port                integer,
backend_start              timestamptz,
xact_start                 timestamptz,
query_start                timestamptz,
waiting                    boolean,
current_query              text,
Datestamp                  timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (LogWaitingPgStatActivityID)
);

ALTER TABLE cron.LogWaitingPgStatActivity OWNER TO pgcronjob;
