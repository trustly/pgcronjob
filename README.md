# pgcronjob

Run PostgreSQL user-defined database functions in a cron like fashion.

## Interface

The user-defined function must return the pgcronjob-defined ENUM type BatchJobState.
BatchJobState has two values, 'AGAIN' or 'DONE'.
If the user-defined function returns 'AGAIN', pgcronjob will run the function again in due time,
and if 'DONE' is returned, it will never run the function ever again.

This is to protect against accidents since boolean values can easily be misinterpeted while the words AGAIN and DONE are much more precise.

This example function is included as an example:

    CREATE OR REPLACE FUNCTION cron.Function_Template_Skeleton()
    RETURNS batchjobstate
    LANGUAGE plpgsql
    SET search_path TO public, pg_temp
    AS $FUNC$
    DECLARE
    BEGIN
    RAISE NOTICE 'Hello world!';
    PERFORM pg_sleep(random());
    RAISE NOTICE 'Slept for a while.';
    IF random() < 0.5 THEN
        -- Tell cron.Run() we have more work to do and we want it to run us again in due time
        RAISE NOTICE 'See you again!';
        RETURN 'AGAIN';
    ELSIF random() < 0.5 THEN
        -- Throw error to cron.Run() to test errors
        RAISE EXCEPTION 'Simulate error in CronJob function';
    ELSE
        -- Tell cron.Run() we're done and we don't want it to run us ever again
        RAISE NOTICE 'Bye world!';
        RETURN 'DONE';
    END IF;
    END;
    $FUNC$;
    
    GRANT EXECUTE ON FUNCTION cron.Function_Template_Skeleton() TO pgcronjob;

Then all you have to do is to register the function to be run by pgcronjob:

    # SELECT cron.Register('cron.function_template_skeleton()');
     register 
    -----------
            1
    (1 row)

And then setup your normal OS cron to run pgcronjob.sh every minute.
pgcronjob.sh will then in a while loop call the database function cron.Run() as long as it returns 'AGAIN',
which is does as long as there is some cronjob that should be executed.

If your OS cron would execute pgcronjob.sh again while it's already running, it will simply return immediately
because cron.Run() will return 'AGAIN' if it detects it's already running. This is implemented using pg_try_advisory_xact_lock().

This prevents cron.Run() from ever occupying more than one CPU core, which could be considered a feature or a misfeature.

Support to control how many concurrent cron.Run() processes that can run in parallel might be added in the future. Patches welcome.

If you want other settings than the default which is to just run the function until it returns 'DONE',
then such special settings can easily be defined when registering the function:

    # SELECT cron.Register('cron.function_template_skeleton()',
        _RunIfWaiting  := TRUE,
        _RetryOnError               := TRUE,
        _RunAfterTimestamp          := '2016-05-25 03:00:00+01',
        _RunUntilTimestamp          := '2016-05-28 04:00:00+01',
        _RunAfterTime               := '03:00:00',
        _RunUntilTime               := '04:00:00',
        _IntervalAGAIN              := '1 second',
        _IntervalDONE               := '30 minutes'
    );

None, some, or all of the settings can be specificed when registering the function.

To disable the cronjob, use the cron.Disable() function:

    SELECT cron.Disable('cron.function_template_skeleton()');
     cronjob_disable 
    -----------------
                   1
    (1 row)

To re-enable it, use the cron.Enable() function:

    SELECT cron.Enable('cron.function_template_skeleton()');
     cronjob_enable 
    ----------------
                  1
    (1 row)

## Security

The system makes sure the functions in Jobs really are meant to be executed by checking two conditions that must both be met:

- The function's returned type is BatchJobState
- The pgcronjob user has been explicitly granted EXECUTE on the function.

If the user-defined function would not return AGAIN or DONE, such as NULL, then pgcronjob will throw an exception and only rerun the function if RetryOnError IS TRUE.

## Settings

The settings are conditions that must all be TRUE for the cronjob to run, i.e. they are AND'd together.

Always NOT NULL:
- Enabled boolean NOT NULL DEFAULT TRUE: Controls whether the cronjob is enabled or not.
- RunIfWaiting boolean NOT NULL DEFAULT FALSE: Controls whether to run the cronjob or not if there are other waiting db txns (pg_stat_activity.waiting).
- RetryOnError boolean NOT NULL DEFAULT FALSE: Controls whether to run the cronjob ever again if the user-defined function would throw an error.

Can be NULL (which means setting is ignored):
- RunAfterTimestamp timestamptz: Run only after the specified timestamp.
- RunUntilTimestamp timestamptz: Run only until the specified timestamp.
- RunAfterTime time: Run only after the specified time of the day.
- RunBeforeTime time: Run only until the specified time of the day.
- IntervalAGAIN interval: Time to sleep between each db txn commit to spread the load.
- IntervalDONE interval: Time to sleep after a cron job has completed and has no more work to do for now.

## Logging

For each executed cronjob, we log the following:

- FirstRunStartedAt         timestamptz: The timestamp when the job ran the first time. NULL means it hasn't run even once yet.
- FirstRunFinishedAt        timestamptz: The timestamp when the job finished the first time. NULL means it hasn't finished even once yet.
- LastRunStartedAt          timestamptz: The timestamp when the job ran the last time. NULL means it hasn't run even once yet.
- LastRunFinishedAt         timestamptz: The timestamp when the job finished the last time. NULL means it hasn't finished even once yet.
- BatchJobState             batchjobstate: The BatchJobState for the last run. AGAIN means the job wants to be run again. DONE means the job will not be run again, unless manually overridden by changing this column to AGAIN.
- LastSQLSTATE              text: If NOT NULL, it means the last run didn't finish due to an error. This column shows the SQLSTATE code for the error.
- LastSQLERRM               text: IF NOT NULL, it means the last run didn't finish due to an error. This column shows the SQLERRM text message for the error.

The below columns show the SUM() for pg_catalog.pg_stat_xact_user_tables column,
giving you information on the total I/O read/write stats for each cron job execution,
perhaps useful if you want to detect abnormalities or integrate with some monitoring tool like Munin:

- seq_scan                  bigint: SUM(seq_scan)
- seq_tup_read              bigint: SUM(seq_tup_read)
- idx_scan                  bigint: SUM(idx_scan)
- idx_tup_fetch             bigint: SUM(idx_tup_fetch)
- n_tup_ins                 bigint: SUM(n_tup_ins)
- n_tup_upd                 bigint: SUM(n_tup_upd)
- n_tup_del                 bigint: SUM(n_tup_del)
- n_tup_hot_upd             bigint: SUM(n_tup_hot_upd)

## Installation

    createuser pgcronjob
    Shall the new role be a superuser? (y/n) n
    Shall the new role be allowed to create databases? (y/n) n
    Shall the new role be allowed to create more new roles? (y/n) n
    psql -f install.sql
    crontab pgcronjob.crontab
