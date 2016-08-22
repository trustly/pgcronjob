CREATE TABLE cron.LogWaiting (
LogWaitingID        serial  NOT NULL,
NumPIDs             integer NOT NULL,
MaxSeconds          integer NOT NULL,
Datestamp           timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (LogWaitingID)
);

ALTER TABLE cron.LogWaiting OWNER TO pgcronjob;
