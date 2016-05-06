#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DBD::Pg;
use Time::HiRes qw(time);
use Data::Dumper;

$| = 1;

my @connect = ("dbi:Pg:", '', '', {pg_enable_utf8 => 1, RaiseError => 1, PrintError => 0, AutoCommit => 1});

sub SQL_Run {
    my $ProcessID = shift;
    die "Invalid ProcessID: $ProcessID" unless $ProcessID =~ m/^\d+$/;
    return "SELECT BatchJobState, RunAgainInSeconds, NewProcessID FROM cron.Run(_ProcessID := $ProcessID)";
}

my $Processes = {};
$Processes->{0}->{DatabaseHandle} = DBI->connect(@connect) or die "Unable to connect";
$Processes->{0}->{Run} = $Processes->{0}->{DatabaseHandle}->prepare(SQL_Run(0), {pg_async => PG_ASYNC});
$Processes->{0}->{RunAgainAtTime} = time;

while (1) {
    foreach my $ProcessID (sort keys %{$Processes}) {
        if ($Processes->{$ProcessID}->{RunAgainAtTime}) {
            next if $Processes->{$ProcessID}->{RunAgainAtTime} > time;
            $Processes->{$ProcessID}->{Run}->execute();
            delete $Processes->{$ProcessID}->{RunAgainAtTime};
        } elsif ($Processes->{$ProcessID}->{Run}->pg_ready) {
            my $rows = $Processes->{$ProcessID}->{Run}->pg_result;
            die "Unexpected number of rows: $rows" unless $rows == 1;
            my ($BatchJobState, $RunAgainInSeconds, $NewProcessID) = $Processes->{$ProcessID}->{Run}->fetchrow_array();
            if ($BatchJobState eq 'DONE' && !defined($RunAgainInSeconds)) {
                $Processes->{$ProcessID}->{Run}->finish;
                $Processes->{$ProcessID}->{DatabaseHandle}->disconnect;
                delete $Processes->{$ProcessID};
            } else {
                $Processes->{$ProcessID}->{RunAgainAtTime} = time() + $RunAgainInSeconds;
            }
            die "cron.Run() returned an invalid batchjobstate: $BatchJobState" unless $BatchJobState =~ m/^(AGAIN|DONE)$/;
            if ($NewProcessID) {
                die "ProcessID $NewProcessID already exists" if exists $Processes->{$NewProcessID};
                $Processes->{$NewProcessID}->{DatabaseHandle} = DBI->connect(@connect) or die "Unable to connect";
                $Processes->{$NewProcessID}->{Run} = $Processes->{$NewProcessID}->{DatabaseHandle}->prepare(SQL_Run($NewProcessID), {pg_async => PG_ASYNC});
                $Processes->{$NewProcessID}->{Run}->execute();
            }
        }
    }
}
