#!/usr/bin/perl
#
# File: calc_elapsed_time.pl by Marc Perry
# 
# I wrote this script to let me automate my calculations for how long various steps
# in the DCC Pipeline were taking based on an html2text conversion of
# this page: http://submit.modencode.org/submit/administration
# 
# Last Updated: 2013-11-06, Status: prototype

use strict;
use warnings;
use Data::Dumper;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;

# input for this script is an ascii tsv file
# where the first column contains the start time
# and the second column contains the end time:
# 10:35:44        10:35:45
# 10:28:12        10:29:55
# 10:41:06        10:44:33

my $strp = DateTime::Format::Strptime->new(pattern   => '%T',);
my $d = DateTime::Format::Duration->new(pattern => '%T',);
    
while ( <> ) {
    chomp;
    my ( $t1, $t2, ) = split /\t/, $_;
    my $dt1 = $strp->parse_datetime($t1);
    my $dt2 = $strp->parse_datetime($t2);
    my $elapsed = $dt2->subtract_datetime($dt1);
    # print Dumper(\$elapsed), "\n";
    print $d->format_duration($elapsed), "\n";
} # close while loop
continue {
    close $ARGV if eof;
}

exit;

__END__

