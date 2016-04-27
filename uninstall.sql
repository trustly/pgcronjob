ROLLBACK;
\set AUTOCOMMIT OFF

BEGIN;

DROP FUNCTION public.CronJob_Function_Template_Skeleton();

DROP FUNCTION public.CronJob_Disable(
_SchemaName   text,
_FunctionName text
);

DROP FUNCTION public.CronJob_Enable(
_SchemaName   text,
_FunctionName text
);

DROP FUNCTION public.CronJob_Register(
_SchemaName                 text,
_FunctionName               text,
_RunEvenIfOthersAreWaiting  boolean,
_RetryOnError               boolean,
_RunAfterTimestamp          timestamptz,
_RunUntilTimestamp          timestamptz,
_RunAfterTime               time,
_RunUntilTime               time,
_RunInterval                interval,
_SleepInterval              interval
);

DROP FUNCTION public.CronJob();

DROP FUNCTION public.CronJob_Function_Is_Valid(
_SchemaName   text,
_FunctionName text
);

DROP FUNCTION public.CronJob_No_Waiting();

DROP TABLE public.CronJobLog;

DROP TABLE public.CronJobs;

DROP TYPE public.BatchJobState;

COMMIT;
