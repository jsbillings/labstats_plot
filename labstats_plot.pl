#! /usr/bin/env perl
###################################################################
#	labstats_data.pl - plots compiled labstats statistics or 
#			   statistics for a single host in gnuplot
#
#	Author: Paul Doerr
#	Version: 1.0
#	Date: 7 Oct 2011
###################################################################

use strict;
use warnings;

our $VERSION="1.0";

use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

our($opt_f,$opt_h,$opt_p);
getopts('f:h:p:') || exit 1;

if (!$opt_f) {
	die "No filename specified. Use '-f <datafile>' or --help for more information, stopped";
}
if  (!($opt_p =~ /^usedmem$|^pagefaults$|^cpupercent$|^cpuload$|^users$/)) {
	die "Invalid plotting option. Use '-p <option>' or --help for more information, stopped";
}

open(my $data, "<", $opt_f)			#open input data file
	or die "cannot open $opt_f: $!";

open(my $parsed, ">", "labstats_tmp")		#open temporary output file (used by gnuplot)
	or die "cannot open temporary file: $!";

my $secStart = 0;				#Starting time of 300 seconds (5 minute) period of averaging
my $sec = 0;					#Current time in seconds
my $n = 0;					#Number of data points processed up to this time
my $total = 0;					#Total value (to be averaged) for this time period
while (my $current = <$data>) {
	
	#If host is specified, only graph points from that host
	if($opt_h) {
		if ($current =~ /(\d\d\d\d\d\d\d\d\d+)\t$opt_h\t(\w)\t([\w\ \-]+)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)/) {
			print $parsed $1;
			print $parsed "\t";
			if($opt_p eq "usedmem") {
				print $parsed $7;
			}
			if($opt_p eq "pagefaults") {
				print $parsed $9;
			}
			if($opt_p eq "cpupercent") {
				print $parsed $10;
			}	
			if($opt_p eq "cpuload") {
				print $parsed $11;
			}
			if($opt_p eq "users") {
				print $parsed $12;
			}
			print $parsed "\n";
		}
	}
	#If no host, average values for all clients over a period of time
	else {
		$current =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
		$sec = $2*2629744 + $3*86400 + $4*3600 + $5*60 + $6;
		if(($sec - 300)>$secStart) {
			print $parsed $1.$2.$3.$4.$5.$6;
			print $parsed "\t";
			if($n>0) {
				print $parsed $total/$n;
			}
			else {
				print $parsed $total;
			}
			print $parsed "\n";
			$secStart = $sec;
			$n = 0;
			$total = 0;
		}
		if ($current =~ /(\d\d\d\d\d\d\d\d\d+)\t[\w\ \.]+\t(\w)\t([\w\ \-]+)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)\t(\d+\.?\d*)/) {	
			if($opt_p eq "usedmem") {
				$total += $7;
			}
			if($opt_p eq "pagefaults") {
				$total += $9;
			}
			if($opt_p eq "cpupercent") {
				$total += $10;
			}	
			if($opt_p eq "cpuload") {
				$total += $11;
			}
			if($opt_p eq "users") {
				$total += $12;
			}
			$n++;
		}
	}	
			
}
close($data);
close($parsed);

system "gnuplot -e 'load \"labstats_gnuplot\"'";

exit(0);

sub HELP_MESSAGE {
	print "Usage: labstats_plot.pl [-fhp]\n";
	print "\n";
	print "Options:\n";
	print "--help		Show this help message and exit\n";
	print "-f=DATAFILE	Specify labstats data file (required)\n";
	print "-h=HOST		Specify a system (the whole hostname, 1 computer only) to plot stats from\n";
	print "-p=OPTION	Specify what to plot (required)\n";
	print "			Options are: usedmem, pagefaults, cpupercent, cpuload, users\n";
	exit(0);
}
