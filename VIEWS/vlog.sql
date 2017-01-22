CREATE OR REPLACE VIEW cron.vLog AS
SELECT
LogID,
ProcessID,
BatchJobState,
PgBackendPID,
StartTxnAt::time(0),
(FinishedAt-StartedAt)::interval(3) AS Duration,
seq_scan,
seq_tup_read,
idx_scan,
idx_tup_fetch,
n_tup_ins,
n_tup_upd,
n_tup_del
FROM cron.Log;

ALTER TABLE cron.vLog OWNER TO pgcronjob;

