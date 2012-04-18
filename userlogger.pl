#! /usr/bin/env perl

#	userlogger.pl
#	Takes labstat record data from standard input
#	Computes an average usetime of workstations in every lab
#	Prints or plots this data
#	Can also find average memory usage and average CPU percent per lab


use strict;
use warnings;

our $VERSION="1.0";

use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

our($opt_t, $opt_m, $opt_c, $opt_h, $opt_f);
getopts('tmchf:') || die "????????";

our $file = *STDIN;
if ($opt_f) {
	open(my $file, "<", $opt_f)
		or die "cannot open $opt_f: $!";
}

open(my $parsed, ">", "userlogger_tmp")	#open temp gnuplot file
	or die "cannot open temporary file; $!";

#TODO: Plot the data

my %host_minutes;		#time users spent working on the host
my %lab_minutes;		#total use time of all computers in lab
my %host_mem;			#Memory usage (out of total memory) of host
my %lab_mem;			#Memory usage of all computers in lab
my %host_cpupercent;		#CPU utilization of the host
my %lab_cpupercent;		#CPU utilization of all computers in lab
my %win_lab_minutes;
my %lin_lab_minutes;
my %lab_no_hosts;		#number of computers in the lab
my %host_no_entries;		#number of times a host appears in the logfile

my $time;
my $host;
my $os;
my $totalmem;
my $usedmem;
my $cpupercent;
my $users;

my $lab;

#Input a daily log file - for now
while(<$file>) {
	if(/^\s*\S+\s+\S+\s+(\d\d\d\d\d\d\d\d\d\d\d\d\d\d)\s+(\S+)\s+(\S+).+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s+(\S+)\s+\S+$/) {
		$time = $1;
		$host = $2;
		$os = $3;
		$totalmem = $4;
		$usedmem = $5;
		$cpupercent = $6;
		$users = $7;
	
		$host_minutes{"$os:$host"} += 5 * $users;

		$host_mem{"$os:$host"} += $usedmem / $totalmem;

		$host_cpupercent{"$os:$host"} += $cpupercent;

		$host_no_entries{"$os:$host"}++;
	}
}

#Divide host_cpupercent and host_mem by host_no_entries to get average
foreach $host (keys %host_no_entries) {
	$host_mem{$host} /= $host_no_entries{$host};
	$host_cpupercent{$host} /= $host_no_entries{$host};
}

#Add up the time for each host into a lab average
foreach $host (keys %host_minutes) {
	if( $host =~ /^(\S+):(\S+)p\d+\.\S+/) {
		$os = $1;
		$lab = $2;
		$lab_minutes{$lab} += $host_minutes{$host};
		if ($os eq "L") {
			$lin_lab_minutes{$lab} += $host_minutes{$host};
		} else {
			$win_lab_minutes{$lab} += $host_minutes{$host};
		}

		$lab_mem{$lab} += $host_mem{$host};

		$lab_cpupercent{$lab} += $host_cpupercent{$host};

		$lab_no_hosts{$lab}++;
	}
}

#Time logged per lab
print "Use time of lab in minutes\n";
foreach $lab (sort keys %lab_minutes) {
	my $total_usage = $lab_minutes{$lab};
	my $average_usage = $lab_minutes{$lab} / $lab_no_hosts{$lab};

	$lab_mem{$lab} /= $lab_no_hosts{$lab};
	$lab_cpupercent{$lab} /= $lab_no_hosts{$lab};

	my $windows_usage = 0.0;
	if ($win_lab_minutes{$lab}) {
		$windows_usage = 100 * ( ($win_lab_minutes{$lab} / $lab_no_hosts{$lab}) / $average_usage);
	}
	my $linux_usage = 0.0;
	if ($lin_lab_minutes{$lab}) {
		$linux_usage = 100 * ( ($lin_lab_minutes{$lab} / $lab_no_hosts{$lab} ) / $average_usage );
	}
	if($lab_minutes{$lab} > 0) {
		printf "%s: Total: %2.2f, Average: %2.2f, Systems Reporting: %i (Windows: %%%2.1f, Linux: %%%2.1f)\n", $lab, $total_usage, $average_usage, $lab_no_hosts{$lab}, $windows_usage, $linux_usage;
		if($opt_t) {
			print $parsed $lab;
			print $parsed $average_usage;
			print $parsed '\n';
		}
	}
	if($lab_mem{$lab} > 0) {
		printf "%s: Average Mem: %2.2f\n", $lab, $lab_mem{$lab};
		if($opt_m) {
			print $parsed $lab;
			print $parsed $lab_mem{$lab};
			print $parsed '\n';
		}
	}
	if($lab_cpupercent{$lab} > 0) {
		printf "%s: Average CpuPercent: %2.2f\n", $lab, $lab_cpupercent{$lab};
		if($opt_c) {
			print $parsed $lab;
			print $parsed $lab_cpupercent{lab};
			print $parsed '\n';
		}
	}
}

if($opt_m || $opt_t || $opt_c) {
	system "gnuplot -e 'load \"userlogger_gnuplot\"'";
	unlink("userlogger_tmp") or die "Couldn't remove 'userlogger_tmp'";
}

exit(0);
