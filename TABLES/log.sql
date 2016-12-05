CREATE TABLE cron.Log (
LogID             serial        NOT NULL,
JobID             integer       NOT NULL REFERENCES cron.Jobs(JobID),
BatchJobState     batchjobstate,
PgBackendPID      integer       NOT NULL,
StartTxnAt        timestamptz   NOT NULL,
StartedAt         timestamptz   NOT NULL,
FinishedAt        timestamptz   NOT NULL,
seq_scan          bigint        NOT NULL, -- seq_scan
seq_tup_read      bigint        NOT NULL, -- seq_tup_read
idx_scan          bigint        NOT NULL, -- idx_scan
idx_tup_fetch     bigint        NOT NULL, -- idx_tup_fetch
n_tup_ins         bigint        NOT NULL, -- n_tup_ins
n_tup_upd         bigint        NOT NULL, -- n_tup_upd
n_tup_del         bigint        NOT NULL, -- n_tup_del
n_tup_hot_upd     bigint        NOT NULL, -- n_tup_hot_upd
PRIMARY KEY (LogID)
);

ALTER TABLE cron.Log OWNER TO pgcronjob;
