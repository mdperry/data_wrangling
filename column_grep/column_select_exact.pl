#!/usr/bin/perl
#
# File: column_select_exact.pl by Marc Perry
#
# N.B. This is NOT a unix-type filter, so it will not read
# from STDIN, and the main output is not to STDOUT
# 
# As an example, I had a single column of uniq strings, 241 rows (or patterns)
# I used grep -w -f to read that file of patterns and compare it to every row in 
# a file (table) with 130,671 rows.  I used the date; trick to roughly time the
# search, it took about 2'15" on my aging Ubuntu vm.  This script performed the
# same job in 0.07 min, I am not sure what that is in seconds, but it was
# blazingly fast
#
# Last Updated: 2018-08-16, Status: working production script

use strict;
use warnings;
use Getopt::Long;

my $list = q{};
my $table = q{};
my $table_has_hdr;
my $col = q{};
my $version = "0.0001\n";
my $usage = "Usage: column_select_exact.pl -l <list_file> -t <table_file> [-h] -c <column number in table_file>\n";

my $options = <<OPTIONS;
    Usage: column_select_exact.pl -l <list_file> -t <table_file> [-h] -c <column number in table_file>

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

# Process the first tsv table on the command line into a 
# customized data structure
open my ($FH1), '<', $list or die "Could not open $list for reading";

my @strings = <$FH1>;
chomp( @strings );
my %patterns_of;

# one-step conversion to hash using a hash slice
# values are all undef
@patterns_of{@strings} = ();

my $rows = scalar( @strings );
my $patterns = scalar( keys %patterns_of );

if ( $rows == $patterns ) {
    print "Found $rows strings in list file $list\n";
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

my @rows;

# read and process each subsequent line (or record) (or row)
while ( <$FH2> ) {
    chomp;
    my @fields = split(/\t/, $_);
    push @rows, \@fields
} # close while loop
close $FH2;

# Now, open two output filehandles
open my ($MATCH), '>', 'column_select_exact_matched_rows_' . $timestamp . '.tsv' or die "Could not open column_select_exact_matched_rows.tsv for writing: $!";
open my ($NOT), '>', 'column_select_exact_unmatched_rows_' . $timestamp . '.tsv' or die "Could not open column_select_exact_unmatched_rows.tsv for writing: $!";

if ( $table_has_hdr ) {
    print $MATCH $header, "\n";
    print $NOT $header, "\n";
}

my $match = 0;
foreach my $row ( @rows ) {
    if ( $row->[$col] ) {
        if ( exists $patterns_of{$row->[$col]} ) {
            $match = 1;
        }
    }

    if ( $match ) {
        printrow( $MATCH, $row, );
        $match = 0;
    }
    else {
        printrow( $NOT, $row, );
    }
} # close foreach my $row

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



    
