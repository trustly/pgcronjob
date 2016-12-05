# pgcronjob

Run PostgreSQL user-defined database functions in a cron like fashion.

## SCREENSHOT

![screenshot](https://raw.githubusercontent.com/trustly/pgcronjob/master/screenshot.png)

## DEMO

Demo of the example in install.sql: (https://asciinema.org/a/bwdlg8tqabais0p4g8wt2b0sx)

## DESCRIPTION

To run your functions using pgcronjob, your function must return the pgcronjob-defined ENUM type BatchJobState, which has two values, 'AGAIN' or 'DONE'.
This is how your function tells pgcronjob if it wants to be run AGAIN or if the work has completed and we are DONE.
A boolean return value would have worked as well, but boolean values can easily be misinterpeted while the words AGAIN and DONE are much more precise,
so hopefully this will help avoid one or two accidents here and there.

## SYNOPSIS

Run until an error is encountered (DEFAULT):
```
SELECT cron.Register('cron.Example_Random_Error(integer)', _RetryOnError := FALSE);
```

Keep running even if an error is encountered:
```
SELECT cron.Register('cron.Example_Random_Error(integer)', _RetryOnError := TRUE);
```

Allow concurrent execution (DEFAULT):
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _Concurrent := TRUE);
```

Detect and prevent concurrent:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _Concurrent := FALSE);
```

Wait 100 ms between each execution (DEFAULT):
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval);
```

No waiting, execute again immediately:
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '0'::interval);
```

Run cron job in one single process (DEFAULT):
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _Processes := 1);
```

Run cron job concurrently in two separate processes (pg backends):
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _Processes := 2);
```

Don't limit how many cron job functions that can be running in parallell (DEFAULT):
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _ConnectionPool := NULL);
```

Create a connection pool to limit the number of concurrently running processes:
```
SELECT cron.New_Connection_Pool(_Name := 'My test pool', _MaxProcesses := 2);
```

Create a connection pool to limit the number of concurrently running processes:
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _ConnectionPool := 'My test pool');
```

Run until cron job returns DONE, then never run again (DEFAULT):
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalDONE := NULL);
```

Run until cron job returns DONE, then run again after 60 seconds:
```
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalDONE := '60 seconds'::interval);
```

The two examples below uses pg_catalog.pg_stat_activity.waiting or pg_catalog.pg_stat_activity.wait_event depending on the PostgreSQL version.

Don't run cron job if any other PostgreSQL backend processes are waiting (DEFAULT):
```
SELECT cron.Register('cron.Example_Update_Same_Row(integer)', _RunIfWaiting := FALSE);
```

Run cron job even if there are other PostgreSQL backend processes waiting:
```
SELECT cron.Register('cron.Example_Update_Same_Row(integer)', _RunIfWaiting := TRUE);
```
Run at specific timestamp and then forever:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTimestamp := now()+'10 seconds'::interval);
```

Run immediately from now until a specific timestamp in the future:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunUntilTimestamp := now()+'15 seconds'::interval);
```

Run between two specific timestamps:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTimestamp := now()+'20 seconds'::interval, _RunUntilTimestamp := now()+'25 seconds'::interval);
```

Run after a specific time of day and then forever:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTime := now()::time+'30 seconds'::interval);
```

Run immediately from now until a specific time of day:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunUntilTime := now()::time+'35 seconds'::interval);
```

Run between two specific time of day values:
```
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTime := now()::time+'40 seconds'::interval, _RunUntilTime := now()::time+'45 seconds'::interval);
```
