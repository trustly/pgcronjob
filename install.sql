ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
\ir TYPES/batchjobstate.sql
\ir TABLES/cronjobs.sql
\ir TABLES/cronjoblog.sql
\ir FUNCTIONS/cronjob_no_waiting.sql
\ir FUNCTIONS/cronjob_function_is_valid.sql
\ir FUNCTIONS/cronjob_register.sql
\ir FUNCTIONS/cronjob_disable.sql
\ir FUNCTIONS/cronjob_enable.sql
\ir FUNCTIONS/cronjob.sql
GRANT SELECT,UPDATE ON TABLE cronjobs TO pgcronjob;
GRANT INSERT ON TABLE cronjoblog TO pgcronjob;
GRANT USAGE ON SEQUENCE cronjoblog_cronjoblogid_seq TO pgcronjob;

-- For testing only, remove these lines in production:
\ir FUNCTIONS/cronjob_function_template_skeleton.sql
SELECT CronJob_Register('public','cronjob_function_template_skeleton');

COMMIT;
