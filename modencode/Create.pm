# This is a perl module I use to create new submissions through
# the modENCODE DCC Pipeline.  This version does NOT upload
# any data files
#
# Last Updated: 2012-04-30, Status: works as advertised

package Create;

use strict;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST);
use HTTP::Cookies;
use URI::URL;
use FindBin '$Bin';
use Carp qw(croak carp);

use base 'Exporter';
our @EXPORT_OK = 'fetch_with_login';
our @EXPORT    = 'fetch_with_login';

my %labs = ( Brenner	=> "Celniker, Susan/Brenner, Steven",
             Brent	=> "Celniker, Susan/Brent, Michael",
             Cherbas	=> "Celniker, Susan/Cherbas, Peter",
             Gingeras	=> "Celniker, Susan/Gingeras, Thomas",
             Graveley	=> "Celniker, Susan/Graveley, Brenton",
             Hoskins	=> "Celniker, Susan/Hoskins, Roger",
             Oliver	=> "Celniker, Susan/Oliver, Brian",
             Perrimon	=> "Celniker, Susan/Perrimon, Norbert",
             Celniker	=> "Celniker, Susan/Celniker, Susan",
             Ahmad	=> "Henikoff, Steven/Ahmad, Kamran",
             Henikoff	=> "Henikoff, Steven/Henikoff, Steven",
             Elgin	=> "Karpen, Gary/Elgin, Sarah",
             Kuroda	=> "Karpen, Gary/Kuroda, Mitzi",
             Park	=> "Karpen, Gary/Park, Peter",
             Pirrotta   => "Karpen, Gary/Pirrotta, Vincent",
             Karpen     => "Karpen, Gary/Karpen, Gary",
             Hannon	=> "Lai, Eric/Hannon, Gregory",
             Lai        => "Lai, Eric/Lai, Eric",
             Ahringer   => "Lieb, Jason/Ahringer, Julie",
             Dernburg   => "Lieb, Jason/Dernburg, Abby",
             Desai      => "Lieb, Jason/Desai, Arshad",
             Green      => "Lieb, Jason/Green, Roland",
             Liu        => "Lieb, Jason/Liu, Xiaole",
             Segal      => "Lieb, Jason/Segal, Eran",
             Strome     => "Lieb, Jason/Strome, Susan",
             Lieb       => "Lieb, Jason/Lieb, Jason",
           'Orr-Weaver' => "MacAlpine, David/Orr-Weaver, Terry",
             MacAlpine  => "MacAlpine, David/MacAlpine, David",
           Gunsalus	=> "Piano, Fabio/Gunsalus, Kristin",
           J_Kim	=> "Piano, Fabio/Kim, John",
           Rajewsky	=> "Piano, Fabio/Rajewsky, Nikolaus",
           Piano	=> "Piano, Fabio/Piano, Fabio",
           Gerstein	=> "Snyder, Michael/Gerstein, Mark",
           Hyman	=> "Snyder, Michael/Hyman, Anthony",
           S_Kim	=> "Snyder, Michael/Kim, Stuart",
           Reinke	=> "Snyder, Michael/Reinke, Valerie",
           B_Waterston	=> "Snyder, Michael/Waterston, Robert",
           'Snyder'       => "Snyder, Michael/Snyder, Michael",
           Kent	=> "Stein, Lincoln/Kent, James",
           Lewis	=> "Stein, Lincoln/Lewis, Suzanna",
           Micklem	=> "Stein, Lincoln/Micklem, Gos",
           Stein	=> "Stein, Lincoln/Stein, Lincoln",
           Gerstein	=> "Waterston, Robert/Gerstein, Mark",
           Green	=> "Waterston, Robert/Green, Philip",
           MacCoss	=> "Waterston, Robert/MacCoss, Michael",
           Miller	=> "Waterston, Robert/Miller, David",
           Reinke	=> "Waterston, Robert/Reinke, Valerie",
           Slack	=> "Waterston, Robert/Slack, Frank",
           R_Waterston	=> "Waterston, Robert/Waterston, Robert",
           Bellen	=> "White, Kevin/Bellen, Hugo",
           Bulyk	=> "White, Kevin/Bulyk, Martha",
           Collart	=> "White, Kevin/Collart, Frank",
           Hoskins	=> "White, Kevin/Hoskins, Roger",
           Kellis	=> "White, Kevin/Kellis, Manolis",
           'Posakony' => "White, Kevin/Posakony, James",
           Ren	=> "White, Kevin/Ren, Bing",
           'Russell' => "White, Kevin/Russell, Steven",
           R_White	=> "White, Kevin/White, Robert",
           'K_White'    => "White, Kevin/White, Kevin",
    );

sub fetch_with_login { 
    my $url  = shift;
    my $name = shift;
    my $lab  = shift;

    my $ua = LWP::UserAgent->new; # create a UserAgent object

    # If you login successfully then any cookies are saved in 
    # the same directory for future use
    $ua->cookie_jar(HTTP::Cookies->new(
			file     => "$Bin/Create_cookies.txt",
			autosave => 1,
		    ));
    $ua->env_proxy();

    push @{$ua->requests_redirectable}, 'POST';

    # call a sub-routine below that requests a page
    my $response = get_page($ua,$url); # the page we requested is served
   
    if ($response->decoded_content =~ /modENCODE DCC Submission Pipeline/) {
        print STDERR "Reached the pipeline login page\n";
	$response = do_login($ua,$response,$lab);
    }
    elsif ( $response->decoded_content =~ /Unknown/ ) {
        carp "Could not log in";
        print $response->decoded_content, "\n";
        print "\n\n__END OF ONE ERROR HTML PAGE__\n\n";
        return; # failure = return undef
    }  
    else {
        warn "\tUndetermined problem at the login stage\n";
        return;
    }

    if ($response->decoded_content =~ m{Create new project:</b>}) { 
        print STDERR "We are ready to create a new submission\n";
        $response = create_submission($ua,$response,$name,$lab);
        return $response;
    }
    else {
        print STDERR "Could not reach the 'Create new project' page (for some reason)\n";
        print $response->decoded_content, "\n";
        print "\n\n__END OF ONE ERROR HTML PAGE__\n\n";
        return;
    }
} # close fetch_with_login

# This sub-routine is called by the fetch_with_login sub-routine
sub get_page {
    my $ua  = shift;
    my $url = shift;
    my $response = $ua->get($url);
    warn $response->status_line unless $response->is_success;
    print STDERR " got a page.\n";
    return $response;
} # close sub

# This sub-routine is called by the fetch_with_login sub-routine
sub do_login {
    my %usernames = ( Karpen  => 'mdp-Karpen',
                      Lieb    => 'mdp-Lieb',
                      Ahringer => 'mdp-Lieb',
                      Desai => 'mdp-Lieb',
                      Strome => 'mdp-Lieb',
                      Dernburg => 'mdp-Lieb',
                      Snyder  => 'mdp-Snyder',
                      K_White => 'mdp-White',
                      Russell => 'mdp-White',
                      Posakony => 'mdp-White',
                    );   

    my $ua       = shift;
    my $response = shift;
    my $pi       = shift;

    my $request  = $response->request;
    my $base_uri = $request->uri;
    warn ">> Asked to log in to $base_uri\n";
 
    my $username = $usernames{$pi};
    my $password = 'elegans';    

    my $text          = $response->decoded_content;

    my ($form_uri)    = $text =~ m/<form action="([^"]+)" method="post">/;
    
    my $post_uri   = URI::URL->new($form_uri,$base_uri);

    my $login_request    = POST($post_uri->abs,
				[login           => $username,
				 password        => $password,
                                 url             => "/submit/pipeline/new",
				 commit          => "Log In"]);
    
    my $login_response = $ua->request($login_request);
    if ( $login_response->is_success ) {
        print STDERR "Now Logged in.\n";
        return $login_response;
    }
    else {
        warn $login_response->status_line;
        return;
    }
} # close sub

sub create_submission {
    my $ua       = shift;
    my $response = shift;
    my $name     = shift;
    my $lab      = shift;
    my $pi_name = $labs{$lab};
    my $request  = $response->request;
    my $base_uri = $request->uri;
    my $text          = $response->decoded_content;
    my ($form_uri)    = $text =~ m!<form action="([^"]+)" method="post">!;
    my $post_uri   = URI::URL->new($form_uri,$base_uri);
    my $create_request    = POST($post_uri->abs,
				['project[name]'       => "$name",
                                 'moderator_assigned_id' => '',
                                 'project_type_id'    => "5",
                          'project[project_type_id]'  => "5",
                                 'project_pi_and_lab' => "$pi_name",
				 'commit'             => "Create"]);
      
    my $create_response = $ua->request($create_request);
    if ( $create_response->is_success ) {
        print STDERR "Creation page returned, but don't know status yet.\n";
        return $create_response;
    }
    else {
        warn $create_response->status_line; 
        return;
    }
} # close sub


exit;

=head1 NAME

Create - A module to automate interactions with the modENCODE Data Submission Website


=head1 VERSION

This documentation refers to Create version 0.0.1.

=head1 SYNOPSIS

use Create;

=head1 DESCRIPTION

As originally designed the modENCODE DCC's Data Submission Website was typically
accessed via a web browser and the data liaison would use a mouse and keyboard
to name and create new data submissions, and then select or click on various 
user interface boxes and buttons to create a brand new Data Submission

This module was written to permit modENCODE DCC Data Wranglers (also known as
curators) to automate the creation of multiple brand new Data Submissions relatively
quickly and easily.

=head1 SUBROUTINES/METHODS

fetch_with_login
get_page
do_login
create_submission


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.
(See also “Documenting Errors” in Chapter 13.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.
(See also “Configuration Files” in Chapter 19.)

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

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

=cut



1;
