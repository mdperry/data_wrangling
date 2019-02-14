#!/usr/bin/perl
#
# File: calculate_means_from_a_tsv_table.pl by Marc Perry
# 
# The input for this script is a TSV table where the first row
# contains the file header, and the first column contains
# some sort of ID or name, etc.
# Each row contains a set of values and you want to calculate the
# mean of all those values, and add the calculation as an additional
# final column.  My typical use case: The columns are patient
# sample identifiers and the rows are human gene names.
# The values could be gene expression levels for each gene
# in each patient, or gene copy number levels, etc.
# 
#
# USAGE: ./$0 my_table.tsv > my_table_with_an_extra_column_of_mean_values.tsv
# 
# Last Updated: 2019-02-14; Status: Works as advertised, but some rows have nothing but 'NA'

use strict;
use warnings;
use Statistics::Descriptive;

# Assume that the first row contains field headers:  
my $header = <>;
chomp( $header );
# modify the header row so that it now has one extra
# column
print $header . "\tmean\n";

# process subsequent rows
while ( <> ) {
   chomp;
   my ( $id, @fields, ) = split( /\t/, $_ );

   # Create a new full statistics object
   my $stat = Statistics::Descriptive::Full->new();
   foreach my $field ( @fields ) {
       next if $field =~ m/NA/;
       # add data to the statistics variable
       $stat->add_data($field) if defined $field;       
   } # close foreach loop
   print "$id\t";
   print join("\t", @fields, ), "\t";
   if ( defined $stat->mean() ) {
       print $stat->mean(), "\n";
   }
   else {
       print "NA\n";
   }

} # close while loop

exit;

__END__

