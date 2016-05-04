#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DBD::Pg;

$| = 1;

my @connect = ("dbi:Pg:", '', '', {pg_enable_utf8 => 1, RaiseError => 1, PrintError => 0, AutoCommit => 1});
my $dbh = DBI->connect(@connect) or die "Unable to connect";

my $run = $dbh->prepare("SELECT cron.Run()");

while (1) {
    $run->execute();
    my ($batchjobstate) = $run->fetchrow_array();
    exit unless defined $batchjobstate; # cron.Run() returns NULL if there is a concurrent execution
    if ($batchjobstate eq 'AGAIN') {
        next; # call cron.Run() again immediately since there is more work to do
    } elsif ($batchjobstate eq 'DONE') {
        sleep(1); # no work to do, we're done, sleep 1 second to avoid flooding
    } else {
        die "cron.Run() returned an invalid batchjobstate: $batchjobstate";
    }
}
