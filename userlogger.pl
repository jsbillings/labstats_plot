#! /usr/bin/env perl

#	userlogger.pl
#	Takes labstat record data from standard input
#	Computes an average usetime of workstations in every lab
#	Prints or plots this data


use strict;
use warnings;

#TODO: Plot the data, add file input option, add argument handling

#TODO: Daily memory, usage time, and cpu% per lab and plot


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
while(<STDIN>) {
	if(/^\s*\S+\s+\S+\s+(\d\d\d\d\d\d\d\d\d\d\d\d\d\d)\s+(\S+)\s+(\S+)\s+\S+\s+(\S+).+(\S+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s+(\S+)\s+\S+$/) {
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
	}
	if($lab_mem{$lab} > 0) {
		printf "%s: Average Mem: %2.2f\n", $lab, $lab_mem{$lab};
	}
	if($lab_cpupercent{$lab} > 0) {
		printf "%s: Total: %2.2f, Average Cpu%: %2.2f\n", $lab, $lab_cpupercent{$lab};
	}
}
