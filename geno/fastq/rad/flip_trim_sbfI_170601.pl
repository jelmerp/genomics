#!/usr/bin/perl -w
use strict; use warnings;

my $b = 8;		# set barcode length (Hohenlohe lab 2015 bestRAD barcodes are 8bp)
my $n = 2;		# set number of nucleotides to expect before the barcode (bestRAD libraries run at U. Oregon have 2bp here)
my $c = $b + $n;	# set position for start of enzyme cutsite, which occurs after the initial nucleotides plus the barcode
my $e = 6;		# set length of remaining enzyme cutsite sequence (e.g. 6 for SbfI) -- for other than SbfI, need to change the actual sequence below!!!
# note this is the length of what's left after enzyme digestion, NOT the full length of the enzyme recognition site
# the program expects all correct forward reads to follow the pattern: $n initial nucleotides, then $b nucleotides of barcode, then $e nucleotides of the cutsite

open (IN, $ARGV[0]);	# read file with barcodes
my %counts = ();	# make a hash of barcodes that will be searched
while(<IN>) {		# counts of each barcode can be tracked with this hash, with a few more lines of code below	
	chomp($_);
	$counts{$_} = 0;
}
close IN;

open (IN1, $ARGV[1]);		# read fastq file of raw forward reads
open (IN2, $ARGV[2]);		# read fastq file of raw reverse reads  -- these must have pairs in identical order
open (OUT1, ">$ARGV[3]");	# create fastq outfile for flipped forward reads (cutsite end)
open (OUT2, ">$ARGV[4]");	# create fastq outfile for flipped reverse reads (randomly sheared end)
my $forward; my $reverse; my $barcode;		# establish string variables for all parts of fastq files
my $name1; my $name2; my $third1; my $third2; my $qual1; my $qual2;
while($name1 = <IN1>) {		# start reading through the paired fastq input files
	$name2 = <IN2>;		# read all parts of a single read pair (4 lines in each of the 2 fastq files)
	$forward = <IN1>;
	$reverse = <IN2>;
	$third1 = <IN1>; $third2 = <IN2>; $qual1 = <IN1>; $qual2 = <IN2>;
	my $which = 0; my $for; my $rev;		# establish variables used below
	if(substr($forward, $c, $e) eq "TGCAGG") {			# check for SbfI cutsite in the correct place in forward read
		if(substr($reverse, $c, $e) eq "TGCAGG") {		# check for SbfI cutsite in the correct place in reverse read
			$for = substr($forward, $n, $b);		# this is where a barcode should be if it's in the forward read
			$rev = substr($reverse, $n, $b);		# this is where a barcode should be if it's in the reverse read
			if(exists $counts{$for} && (exists $counts{$rev}) == 0) {	# if a correct barcode and cutsite are in forward but not reverse read...
				$which = 1; $barcode = $for; $counts{$for}++;			# which = 1 means the pair is correctly oriented
			}
			elsif((exists $counts{$for}) == 0 && exists $counts{$rev}) {	# if a correct barcode and cutsite are only in the reverse read...
				$which = 2; $barcode = $rev; $counts{$rev}++;			# which = 2 means the pair needs to be flipped
			}
		}
		else {							# the cutsite is only found in the forward read
			$barcode = substr($forward, $n, $b);			
			if(exists $counts{$barcode}) {$which = 1; $counts{$barcode}++; } # if a correct barcode is also in the forward read, the pair is correctly oriented
		}
	}
	elsif(substr($reverse, $c, $e) eq "TGCAGG") {		# cutsite not in forward read but is in reverse read
		$barcode = substr($reverse, $n, $b);				
		if(exists $counts{$barcode}) {$which = 2; $counts{$barcode}++; }	# if a correct barcode is also in reverse read, pair needs to be flipped
	}								# if a cutsite and correct barcode has not been found in either read, which = 0 at this point
	if($which == 1) {						# if the pair is correctly oriented, print out fastq format for the pair
		my $temp1 = substr($forward, $n);			# trim initial nucleotides off read and quality scores...
		my $temp2 = substr($qual1, $n);				# so that output keeps barcode and cutsite but not other nucleotides...
		print OUT1 "$name1$temp1$third1$temp2";			# and is ready to go into process_radtags
		print OUT2 "$name2$reverse$third2$qual2";
	}
	elsif($which == 2) {						# if the pair needs to be flipped, print out fastq format for the flipped pair
		my $temp1 = substr($reverse, $n);
		my $temp2 = substr($qual2, $n);
		print OUT1 "$name2$temp1$third2$temp2";
		print OUT2 "$name1$forward$third1$qual1";
	}								# if which == 0, nothing is printed out for the pair
}
close IN1;
close IN2;
close OUT1;
close OUT2;

foreach my $key (sort keys %counts) {
	print "$key" . "\t" . "$counts{$key}\n";
}



