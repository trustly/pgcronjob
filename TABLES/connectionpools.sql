CREATE TABLE cron.ConnectionPools (
ConnectionPoolID    serial  NOT NULL,
Name                text    NOT NULL,
MaxProcesses        integer NOT NULL,
LastCycleAt         timestamptz,
ThisCycleAt         timestamptz,
CycleFirstProcessID integer,
PRIMARY KEY (ConnectionPoolID),
UNIQUE(Name),
CHECK(MaxProcesses > 0)
);

ALTER TABLE cron.ConnectionPools OWNER TO pgcronjob;
