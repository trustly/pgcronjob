#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DBD::Pg;

$| = 1;

$SIG{HUP} = "IGNORE";

my @connect = ("dbi:Pg:", '', '', {pg_enable_utf8 => 1, RaiseError => 1, PrintError => 0, AutoCommit => 1, AutoInactiveDestroy => 1});
my $dbh = DBI->connect(@connect) or die "Unable to connect";
my $dbh_child;

my $forkedjobid;
my $run = $dbh->prepare('SELECT CronRunState, ForkJobID FROM cron.Run(_PgCrobJobPID := ?)');
my $set_child_pid = $dbh->prepare('SELECT cron.Set_Child_PID(_PgCrobJobPID := ?, _ForkedJobID := ?)');
my $run_child;

my $parent_pid = $$;

while (1) {
    my ($batchjobstate, $forkjobid);
    if (defined $forkedjobid) {
        $run_child->execute($$,$forkedjobid);
        ($batchjobstate, $forkjobid) = $run_child->fetchrow_array();
    } else {
        $run->execute($$);
        ($batchjobstate, $forkjobid) = $run->fetchrow_array();
    }
    if ($forkjobid) {
        my $child_pid = fork();
        if ($child_pid) {
            $set_child_pid->execute($child_pid, $forkjobid);
        } else {
            $dbh = undef;
            $dbh_child = DBI->connect(@connect) or die "Unable to connect";
            $run_child = $dbh_child->prepare('SELECT CronRunState, ForkJobID FROM cron.Run(_PgCrobJobPID := ?, _ForkedJobID := ?)');
            $forkedjobid = $forkjobid;
        }
    }
    exit unless defined $batchjobstate; # cron.Run() returns NULL if there is a concurrent execution
    if ($batchjobstate eq 'AGAIN') {
        next; # call cron.Run() again immediately since there is more work to do
    } elsif ($batchjobstate eq 'DONE') {
        sleep(1); # no work to do, we're done, sleep 1 second to avoid flooding
    } else {
        die "cron.Run() returned an invalid batchjobstate: $batchjobstate";
    }
}
