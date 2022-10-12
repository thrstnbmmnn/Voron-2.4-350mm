#!/usr/bin/perl

use List::Util qw( min max );
use Statistics::Basic qw(:all);
use Text::Table;
use Data::Dumper;
use strict;

my $CONFIG = '/home/pi/config/klicky-z-calibration.cfg';
my $LOGS = '/home/pi/logs/';

my $max_dev;
open IN,"<$CONFIG" or die "Can't open $CONFIG for reading: $!";
while (<IN>) {
	next unless /^max_deviation: (.*?)$/;
	$max_dev = $1;
}
if (!$max_dev) { 
	print STDERR "Couldn't detect max_deviation from $CONFIG, assuming 1.0\n"; 
	$max_dev = 1.0;
} else {
	print STDERR "Max deviation detected as $max_dev\n";
}

my $data_in = `grep ^Z-CALIBRATION $LOGS/klippy.log*`;

if (!$data_in) { die "Didn't get any Z-CALIBRATION data from $LOGS/klippy.log*. Are you sure you have Z-Calibration enabled and have set \$LOGS correctly?\n"; }

my @data = split /\n/,$data_in;

my $total = 0;
my $count = 0;
my %data;

my $sep = \'│';

my $tb = Text::Table->new($sep,' ',$sep,'Endstop',$sep,'Nozzle',$sep,'Switch',$sep,'Probe',$sep,'Offset',$sep);

foreach (@data) {
	#print "$_\n";
	$total++;
	my ($endstop, $nozzle, $switch, $probe, $offset) = $_ =~ /.*?ENDSTOP=(.*?) NOZZLE=(.*?) SWITCH=(.*?) PROBE=(.*?)\s.*?\sOFFSET=(.*?)$/;
	if (abs($offset) > $max_dev) { 
		print STDERR "Offset $offset ignored\n";
		next;
	}
	push @{$data{'endstop'}}, $endstop;
	push @{$data{'nozzle'}}, $nozzle;
	push @{$data{'switch'}}, $switch;
	push @{$data{'probe'}}, $probe;
	push @{$data{'offset'}}, $offset;
	$count++;
	$tb->load([$count,$endstop,$nozzle,$switch,$probe,$offset]);
}

$tb->load([' ',' ',' ',' ',' ',' ']);
$tb->load(["Min:",min(@{$data{'endstop'}}),min(@{$data{'nozzle'}}),min(@{$data{'switch'}}),min(@{$data{'probe'}}),min(@{$data{'offset'}})]);
$tb->load(["Max:",max(@{$data{'endstop'}}),max(@{$data{'nozzle'}}),max(@{$data{'switch'}}),max(@{$data{'probe'}}),max(@{$data{'offset'}})]);
$tb->load(["Median:",median(@{$data{'endstop'}}),median(@{$data{'nozzle'}}),median(@{$data{'switch'}}),median(@{$data{'probe'}}),median(@{$data{'offset'}})]);
$tb->load(["Mean:",mean(@{$data{'endstop'}}),mean(@{$data{'nozzle'}}),mean(@{$data{'switch'}}),mean(@{$data{'probe'}}),mean(@{$data{'offset'}})]);
$tb->load(["Variance:",variance(@{$data{'endstop'}}),variance(@{$data{'nozzle'}}),variance(@{$data{'switch'}}),variance(@{$data{'probe'}}),variance(@{$data{'offset'}})]);
$tb->load(["Std. Dev:",stddev(@{$data{'endstop'}}),stddev(@{$data{'nozzle'}}),stddev(@{$data{'switch'}}),stddev(@{$data{'probe'}}),stddev(@{$data{'offset'}})]);

$tb->rule('=');
#foreach ('endstop','nozzle','switch','probe','offset') { 
#	my @data = @{$data{$_}};
	#	print uc $_ . ": " . (join ", ", @data) . "\n";
	#printf("\tMin:      %-7.3f\n",min(@data));
	#printf("\tMax:      %-7.3f\n",max(@data));
	#printf("\tMedian:   %-7.3f\n",median(@data));
	#printf("\tMean      %-7.3f\n",mean(@data));
	#printf("\tVariance: %-7.3f\n",variance(@data));
	#printf("\tStd. Dev: %-7.3f\n",stddev(@data));
	#print "\n";
	#}

print $tb;

print STDERR "Used $count datapoints out of $total available.\n";

exit 0;

