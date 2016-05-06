#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DBD::Pg;
use Data::Dumper;

$| = 1;

my @connect = ("dbi:Pg:", '', '', {pg_enable_utf8 => 1, RaiseError => 1, PrintError => 0, AutoCommit => 1});

sub SQL_Run {
    my $ProcessID = shift;
    die "Invalid ProcessID: $ProcessID" unless $ProcessID =~ m/^\d+$/;
    return "SELECT BatchJobState, NewProcessID FROM cron.Run(_ProcessID := $ProcessID)";
}

my $Processes = {};
$Processes->{0}->{DatabaseHandle} = DBI->connect(@connect) or die "Unable to connect";
$Processes->{0}->{Run} = $Processes->{0}->{DatabaseHandle}->prepare(SQL_Run(0), {pg_async => PG_ASYNC});
$Processes->{0}->{ExecutionTime} = time;

while (1) {
    foreach my $ProcessID (sort keys %{$Processes}) {
        if ($Processes->{$ProcessID}->{ExecutionTime}) {
            next if $Processes->{$ProcessID}->{ExecutionTime} > time;
            $Processes->{$ProcessID}->{Run}->execute();
            delete $Processes->{$ProcessID}->{ExecutionTime};
        }
        if ($Processes->{$ProcessID}->{Run}->pg_ready) {
            my $rows = $Processes->{$ProcessID}->{Run}->pg_result;
            die "Unexpected number of rows: $rows" unless $rows == 1;
            my ($BatchJobState, $NewProcessID) = $Processes->{$ProcessID}->{Run}->fetchrow_array();
            if ($NewProcessID) {
                die "ProcessID $NewProcessID already exists" if exists $Processes->{$NewProcessID};
                $Processes->{$NewProcessID}->{DatabaseHandle} = DBI->connect(@connect) or die "Unable to connect";
                $Processes->{$NewProcessID}->{Run} = $Processes->{$NewProcessID}->{DatabaseHandle}->prepare(SQL_Run($NewProcessID), {pg_async => PG_ASYNC});
                $Processes->{$NewProcessID}->{Run}->execute();
            }
            if ($BatchJobState eq 'AGAIN') {
                # call cron.Run() again immediately since there is more work to do
                $Processes->{$ProcessID}->{ExecutionTime} = time;
            } elsif ($BatchJobState eq 'DONE') {
                # no work to do, we're done, sleep 1 second to avoid flooding
                $Processes->{$ProcessID}->{ExecutionTime} = time+1;
            } else {
                die "cron.Run() returned an invalid batchjobstate: $BatchJobState";
            }
        }
    }
}
