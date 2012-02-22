#! /usr/bin/env perl

#	userlogger.pl
#	Takes labstat record data from standard input
#	Computes an average usetime of workstations in every lab
#	Prints or plots this data


use strict;
use warnings;

#TODO: Plot the data, add file input option, add argument handling




my %host_minutes;		#time users spent working on the host
my %lab_minutes;		#total use time of all computers in lab
my %win_lab_minutes;
my %lin_lab_minutes;
my %lab_average_minutes;	#average minutes at a computer in the lab
my %lab_no_hosts;		#number of computers in the lab

my $time;
my $host;
my $os;
my $users;

my $lab;

while(<STDIN>) {
	if(/^\s*\S+\s+\S+\s+(\d\d\d\d\d\d\d\d\d\d\d\d\d\d)\s+(\S+)\s+(\S+).+(\S+)\s+\S+$/) {
		$time = $1;
		$host = $2;
		$os = $3;
		$users = $4;
	
		$host_minutes{"$os:$host"} += 5 * $users;
	}
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
		$lab_no_hosts{$lab}++;
	}
}

#Time logged per lab
print "Use time of lab in minutes\n";
foreach $lab (sort keys %lab_minutes) {
	my $total_usage = $lab_minutes{$lab};
	my $average_usage = $lab_minutes{$lab} / $lab_no_hosts{$lab};
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
}
