#!/usr/bin/perl
#
# File: chromosome_histogram_bin_maker.pl by Marc Perry
# based on my previous script histogram_bin_maker.pl by Marc Perry
#
# This script takes a file containing 2 columns, the chromosome name
# and the position of the feature on that chromosome, and prints out a
# separate table with a uniform bin size and the count in that bin.
# for each chromosome
#
# 
# USAGE: script.pl <binsize> <filename> 
#
# Last Updated: 2018-06-17, Status: Working Production Script

use strict;
# use warnings;

my $binsize = shift or die "\nPlease provide a positive integer bin size as the first argument on the command line $!";

# print STDERR "\$binsize = $binsize\n";

my $data_file = shift or die "\nThe second argument on the command line must be a text file containing a single column of sorted numbers: $!";

my %chroms = ();
open (my $FH, "<", $data_file) or die "\nCould not open $data_file for reading: $!";
while ( <$FH> ) {
    chomp;
    my ( $chrom, $pos, ) = split( /\t/, $_ );
    push @{$chroms{$chrom}}, $pos;
} # close while loop

close $FH;

foreach my $chr ( sort keys %chroms ) {
    open my ($OUT), '>', $chr . "_histogram.tsv" or die "Could not open file for writing.";
    my $count = 0;
    my $new_binsize = $binsize;
    my @positions = sort { $a <=> $b } @{$chroms{$chr}};
    foreach my $pos ( @positions ) {
        next if $pos == 0;
        if ( $pos <= $new_binsize ) {
            $count++;
            next;
        } 
        else {                
            print $OUT "$new_binsize\t$count\n";
            $count = 0;
            $new_binsize += $binsize;
            if ( $pos <= $new_binsize ) {
                $count++;
                next;
            }
            else {
                while ( $pos > $new_binsize ) {
                    print $OUT "$new_binsize\t0\n";
                    $new_binsize += $binsize;
                } # close inner while loop
                $count++;
                next;
            } # close inner if/else
        } # close outer if/else       
    } # close inner foreach loop
    close $OUT;
} # close main foreach loop

exit;

__END__

