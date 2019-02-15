#!/usr/bin/perl
#
# File: fastcolumngrep.pl by Marc Perry
#
# N.B. This is NOT a unix-type filter, so it will not read
# from STDIN, and the main output is not to STDOUT
# 
# Instead of building a second data structure for the table
# I am going to modify this so that each incoming record in the
# table gets processed right away.  This will involve opening
# The file handles for printing before processing the incoming
# Table
# 
# Last Updated: 2016-05-20, Status: testing

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my $list = q{};
my $table = q{};
my $table_has_hdr;
my $col = q{};
my $version = "0.0001\n";
my $usage = "Usage: fastcolumngrep.pl -l <list_file> -t <table_file> [-h] -c <column number in table_file>\n";

my $options = <<OPTIONS;
    Usage: fastcolumngrep.pl -l <list_file> -t <table_file> [-h] -c <column number in table_file>

    Options: 
        -l <list_file>     Specify single column text file containing the text patterns you wish to look for in the table_file
        -t <table_file>    Specify table file that you want to search 
        -c <column number> Specify the column number in the table that the grep will search when comparing the strings from the list
        -h                 Boolean, if present specifies that the table_file has a header row, and this will be propagated to the output
        --version          Print version information
        --usage            Print the usage line of this summary
        --help             Print this summary
        --man              Print the complete manpage based on the POD in this file

OPTIONS

use Exception::Class ( 'Version', 'Usage', 'Help', 'Man', );

my $options_okay = GetOptions (
    'list=s'   => \$list,
    'table=s'  => \$table,
    'header'   => \$table_has_hdr,
    'column=i' => \$col,    
    'version'  => sub {Version->throw($version); },
    'usage'    => sub {Usage->throw($usage); },
    'man'      => sub {Man->throw(); },
);

Usage->throw() unless $options_okay;

unless ( defined($list) && -f $list ) {
    Usage->throw($usage);
}

unless ( defined($table) && -f $table ) {
    Usage->throw($usage);
}

unless ( defined($col) && $col =~ m/^\d+$/ ) {
    Usage->throw($usage);
}

# convert column numbering in ascii file to Perl array
# numbering system:
$col = $col - 1;

print STDERR scalar localtime, "\n";
my @now = localtime();
my $timestamp = sprintf( "%04d_%02d_%02d_%02d%02d", $now[5]+1900, $now[4]+1, $now[3], $now[2], $now[1], );

# Process the incoming list from the command line into a 
# customized data structure
open my ($FH1), '<', $list or die "Could not open $list for reading";

# This _could_ use up a lot of memory if your incoming list is
# large, like that time I had 2 million IDs in one column
my @strings = <$FH1>;
chomp( @strings );
my %patterns_of;

# one-step conversion to hash using a hash slice
# values are all undef
@patterns_of{@strings} = ();

if ( scalar( @strings ) == scalar( keys %patterns_of ) ) {
    print "Found ", scalar( @strings ), " strings in list file $list\n";
}
else {
    print "Looks like the list of string patterns in file $list is not unique\n";
}

# make sure that the list of incoming pattern strings
# contains only one copy of each string
@strings = sort keys %patterns_of;

open my ($FH2), '<', $table or die "Could not open $table for reading: $!";
my $header = q{};

if ( $table_has_hdr ) {
    $header = <$FH2>;  
    chomp $header;
}

# Now, open two output filehandles
open my ($MATCH), '>', 'columngrep_matched_rows_' . $timestamp . '.tsv' or die "Could not open columngrep_matched_rows.tsv for writing: $!";
open my ($NOT), '>', 'columngrep_unmatched_rows_' . $timestamp . '.tsv' or die "Could not open columngrep_unmatched_rows.tsv for writing: $!";

if ( $table_has_hdr ) {
    print $MATCH $header, "\n";
    print $NOT $header, "\n";
}


# read and process each subsequent line (or record) (or row)
while ( <$FH2> ) {
    chomp;
    my @fields = split(/\t/, $_);
    my $match = 0;
    if ( $fields[$col] ) {
        if ( exists $patterns_of{$fields[$col]} ) {
            $match = 1;
        }
    }

    if ( $match ) {
        printrow( $MATCH, \@fields, );
        $match = 0;
    }
    else {
        printrow( $NOT, \@fields, );
    }
} # close while loop

close $FH2;
close $MATCH;
close $NOT;

END {
    no integer;
    printf( STDERR "Running time: %5.2f minutes\n",((time - $^T) / 60));
} # close END block

exit;

sub printrow {
    my ( $FH, $row, ) = @_;
    my @values = @{$row};
    print $FH join( "\t", @values, ), "\n";
} # close sub

__END__

2016-05-30 Here is an example of using this fastcolumngrep.pl script on a node on the OICR HPC
> fastcolumngrep.pl -l icgc_MUtations_ids_110_most_abundant.txt -t uniq_MUtation_DOnor_project_multiple_MUtations_only.tsv -h -c 1
Mon May 30 13:06:55 2016
Found 110 strings in list file icgc_MUtations_ids_110_most_abundant.txt
Running time:  0.35 minutes

The file I wanted had about 6500 matching rows
The table file had over 5 million rows:
> wc -l columngrep_unmatched_rows_2016_05_30_1306.tsv 
5,068,181 columngrep_unmatched_rows_2016_05_30_1306.tsv
    
