CREATE OR REPLACE VIEW cron.vWaiting AS
SELECT DISTINCT ON (X.NumPIDs, X.MaxSeconds)
X.NumPIDs,
X.MaxSeconds,
X.MinDatestamp,
X.MaxDatestamp,
X.COUNT,
cron.LogWaitingPgStatActivity.usename,
cron.LogWaitingPgStatActivity.current_query
FROM (
    SELECT
        cron.LogWaiting.NumPIDs,
        cron.LogWaiting.MaxSeconds,
        MIN(cron.LogWaiting.LogWaitingID) AS LogWaitingID,
        MIN(cron.LogWaiting.Datestamp) AS MinDatestamp,
        MAX(cron.LogWaiting.Datestamp) AS MaxDatestamp,
        COUNT(*)
    FROM cron.LogWaiting
    GROUP BY cron.LogWaiting.NumPIDs, cron.LogWaiting.MaxSeconds
ORDER BY cron.LogWaiting.NumPIDs, cron.LogWaiting.MaxSeconds
) AS X
LEFT JOIN cron.LogWaitingPgStatActivity ON (cron.LogWaitingPgStatActivity.LogWaitingID = X.LogWaitingID)
ORDER BY X.NumPIDs, X.MaxSeconds, cron.LogWaitingPgStatActivity.xact_start;

ALTER TABLE cron.vWaiting OWNER TO pgcronjob;
