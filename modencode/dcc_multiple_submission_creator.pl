#!/usr/bin/perl
#
# File: dcc_multiple_submission_creator.pl written by Marc Perry 
#
# This script takes a tab-separated text file specified on the
# command line and parses each record.  The records contain
# the name of the new submission, and the name of the lab; this
# script does NOT upload any files, it just creates new submissions
#
# N.B. If it works successfully this script prints out a table with 
# the new DCC ID and name (as well as the URL) to a file named 
# "new_submission_table.txt".  If it doesn't work, it prints the bad
# HTML pages to STDOUT, so it is best to redirect the output to a
# text file
#
#
# Last Updated: 2012-11-23, Status: working production script

use strict;

my $root_dir;
BEGIN {
    $root_dir = $0;
    $root_dir =~ s/[^\/]*$//;
    $root_dir = "./" unless $root_dir =~ /\//;
    push @INC, $root_dir;
}
use URI::URL;
use Create;

use constant CREATION_PAGE => 'http://submit.modencode.org/submit/pipeline/new';

if (!$ARGV[0]) {
    print STDERR "\nUsage:\n";
    print STDERR "$0 file.txt > error_log.txt\n\n";
    exit;
}

my $runtime;
my $total_time;
my $counter;
my $dcc_id;
my $new_name;

print STDERR "\n", scalar localtime, " Job initiated.\n";

# Incoming data table for this script contains two tab-separated columns:
# Col. 1 = Name for the newly created submission
# Col. 2 = PI's name for this submission, i.e., 'Karpen' or 'K_White'

open my ($TABLE), '>', 'new_submission_table.txt' or die "Could not open new_submission_table.txt for writing: $!";
while (<>) {
    chomp;
    my $start = time;
    my ( $name, $pi ) = split(/\t/, $_) or warn "Could not parse line $.: \n $_";
    print STDERR "\n||>>==--++ Creating a new modENCODE DCC Pipeline submission for $pi: $name\n";
    print STDERR "Getting the Create a New Submission page . . .";

    # Call a sub-routine in Create.pm that launches LWP::UserAgent
    # passing over the constant and the 2 fields captured from the
    # current record

    if ( my $response = fetch_with_login( CREATION_PAGE, $name, $pi ) ) {
        # when the submit process succeeds you get back the "show" page:
        if ( $response->decoded_content =~ m{/submit/pipeline/show} ) {
            $runtime = time - $start;
            $total_time += $runtime;
            if ( $response->decoded_content =~ m{/submit/pipeline/ftp_selector/(\d+)"}) {
                $dcc_id = $1;
            }
            else {
                print STDERR "\tCould not find a regex pattern match for a new DCC_ID on this page.\n";
            }

            if ( $response->decoded_content =~ m{<b>Submit data to project\s*'([^']+)':</b>} ) {
                $new_name = $1;
            }
            else {
                print STDERR "\tCould not find a regex pattern match for the Pipeline name for this submission.\n";
            }

            print $TABLE $new_name, "\t", $dcc_id, "\t", 'modENCODE_' . $dcc_id, "\t", 'http://submit.modencode.org/submit/pipeline/show/' . $dcc_id, "\n" if $dcc_id;

            print STDERR "Ok, apparently we queued up $name to create in $runtime sec.\n";
            $counter++;
            sleep 10; # added this so that we don't continually hammer at the server
            $total_time += 10;
        }
        else {
             warn "\n\tWARNING:\tCreation attempt failed for $name!\n";
             $total_time += $runtime;
             $counter++;
             next;
        }
    }
    else {
        print STDERR "\$response was empty/undef for $name . . . skipping\n";
        next;
    }
} # close while loop
close $TABLE;

print STDERR "Job completed; created $counter submissions in ", $total_time / 60, " min.\n";
print STDERR scalar( localtime ), "\n\n";

END {
    no integer;
    printf( STDERR "Running time: %5.2f minutes\n",((time - $^T) / 60));
} # close END block

exit 0;

__END__

=head1 NAME
 
dcc_multiple_submission_creator.pl - A script to automate interactions with the modENCODE Data Submission Website
 
 
=head1 VERSION
 
This documentation refers to dcc_multiple_submission_creator.pl version 0.0.1
 
 
=head1 USAGE
 
./dcc_multiple_submission_creator.pl two_column_file.tsv > error_log.txt
 
=head1 REQUIRED ARGUMENTS
 
This program needs a two column TSV file as its only argument on the
command line.  If the path to such a file is not provided then the script
exits and prints the usage.  You must create and provide this table; the first
column must be the new "Name" for the modENCODE Submission you want to create
(This should be human-readable, human-friendly, hopefully informative title
for the submission; in some cases the data provider lab will suggest or
provide this name/title, but you may wish/choose to modify and/or clarify
this name/title for the submission).  The second column must be one of the
10 acceptable modENCODE Project lab names that the data submission
Website uses to categorize submissions.
 
=head1 DESCRIPTION
 
As originally designed the modENCODE DCC's Data Submission Website was typically
accessed via a web browser and the data liaison would use a mouse and keyboard
to name and create new data submissions, and then select or click on various 
user interface boxes and buttons to create a brand new Data Submission

This script was written to permit modENCODE DCC Data Wranglers (also known as
curators) to automate the creation of multiple brand new Data Submissions relatively
quickly and easily.
 
 
=head1 DIAGNOSTICS

If the subroutine call to Create.pm fails for the current record in the
incoming data file then the script will print this warning to STDERR
and skip this record 
"\$response was empty/undef for $name . . . skipping\n";

If the page returned by Create.pm does not contain the basic expected 
pattern on the page then the script will print this warning to STDERR 
and skip this record in the incoming table:
WARNING: Creation attempt failed for $name!"

If one of the lines in the incoming two-column TSV file cannot be properly
parsed then this warning will be printed to STDERR:
"Could not parse line $.: \n $_"

After the new submission has been created the script checks to see if everything
looks good by checking the HTML Webpage for the newly generated DCC_ID.  If it
cannot successfully find this DCC_ID on the page the script prints this warning
to STDERR:
"Could not find a regex pattern match for a new DCC_ID on this page."

If the page returned by Create.pm does not contain the new name for this submission
then the script will print this warning to STDERR:
"Could not find a regex pattern match for the Pipeline name for this submission.\n";

=head1 DEPENDENCIES

Requires the Perl module named Create.pm.  N.B. This is not part of the standard
Perl distribution and must be installed from GitHub along with this script.

Also requires URI::URL which must be installed separately from CPAN

=head1 INCOMPATIBILITIES

None are known

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Marc Perry (marc.perry@alumni.utoronto.ca)
Patches are welcome.

=head1 AUTHOR

Marc Perry (marc.perry@alumni.utoronto.ca)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014 Marc Perry (marc.perry@alumni.utoronto.ca). All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

