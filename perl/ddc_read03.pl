#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw( strftime );
# POSIX has a NULL "Constant subroutine main::NULL redefined" by Net::SNMP, so is limited to strftime
use Carp;
use Cwd;
use English qw(-no_match_vars);
use File::stat;
# use File::Path qw(make_path remove_tree);
use File::Basename;
use IPC::Open2;
# use Sys::Hostname;
use feature qw(say switch state);

# use diagnostics;      # Enable for debug
use Data::Dumper;     # Enable for debug
# use Regexp::Debugger; # Enable for debug

our $VERSION = '0.0.02';    # Version number of this script

##  DEFINE FILENAMES FOR CONF AND LOG FILES HERE ##

# File name of conf file (assumed to be in same path as perl script)
my $conf_file = 'ddc.conf';

#### DONT MESS WITH VARIABLES BELOW THIS LINE - these are fixed ####

my $CONF;                # File handle for conf file
my $EMPTY       = q{};   # Empty string the Critic way
my %config      = ();    # initialise hash to hold config



## SUB TO CREATE LOCALTIME FORMATTED STRING ##

sub time_check {
    my $tcheck =
    strftime( '%d/%m/%Y %H:%M:%S', localtime );    # create time stamp string
    return $tcheck;
}

## SUB TO FETCH AND CHECK CONFIG ##
sub get_conf {
    open $CONF, '<', $conf_file
    or die
    "\n   $conf_file cannot be read, this file must exist for the program to run!\n   $conf_file should be in the same directory as the program script\n   Check the file exists and is not currently open in some other program\n\n";
    read_conf();
    close $CONF or carp "Unable to close $conf_file\n";
    
    # Check paramaters in conf file match those expected
    #    conf_file_params();    # Check expected conf file parameters are present
    #    conf_folder_params();
    #    conf_behaviour_params();
    
    return;
}

## SUB TO CREATE A DEFAULT CONF FILE ##

sub create_conf {
    my $conf = << 'TAG';
    
## ddc.conf file
# This conf file is OpenSource whitespace and CasESeniTivE
# Comments are hashed, variables & values have no spaces
# Values are "double" quoted
# A space before a variable name creates a name with a space before it
# ddc.conf defines parameters for dbDotCad to watch for & process
# candidate attribute CAD files.
# These are then use these for bulk import into MongoDB
    
## NAMING ##
    
# USER NAME
# user account name
user_name="alice"

# MAIN DB NAME
# dbDotCad document database name
ddc_dbname="ddc"

# CONNECTION DB NAME
# Connectivity database name
ddc_connections="ddc_con"


## DIRECTORIES - THESE MUST EXIST AND BE WITHIN THE USERS HOME DIRECTORY ##

# WATCH FOLDER
# This is the folder searched for files to be processed
# Must be defined ending in a slash to signify a folder and not a file
# watch_folder="/home/user/"
watch_folder="/home/user/dbdotcad/attout_to_db/"

# DONE DIRECTORY
# The folder used to hold local files after transfer if not deleted
# Must be defined ending in a slash to signify a folder and not a file
# done_dir="/home/user/done/"
done_dir="/home/user/dbdotcad/done/"

# FAILED DIRECTORY
# Folder used to hold attribute files if these have failed during processing
# error_dir="/home/user/failed/"
error_dir="/home/user/dbdotcad/failed/"

# LOG DIRECTORY
# Folder used to hold log files
# Must be defined ending in a slash to signify a folder and not a file
# log_dir="/home/user/log/"
log_dir="/var/www/ddclog/"
 

## BEHAVIOURS ##
    
# ATTRIBUTE FILE NAME, PATTERN MATCH CHECK
# Pattern match required to identify file name for transfer
# Use perl regex format. This is a regex not a glob. Check it works with rxrx.
# regex /^[0-9][0-9]*-[0-9][0-9]*-[0-9][0-9]*-[A-Z][A-Z]*_.*/
# string '123-45-678-MAD_just a test_file.txt'
# fname_match="/^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*/"
fname_match="/^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*/"
 
# GROWING DELAY IN SECONDS
# Duration in whole seconds used to pause and check file for growth
# Minimum is 1 second. Set to a small value if xml trigger file used
# Growth is checked for by comparing file size, modification time and last 20 bytes
growing_time="3"

# DELETE ON SUCCESS
# Set to DELETE for this to be active, i.e.
# delete_on_success="DELETE" -or- "DONT"
# Any setting other than DELETE will move the successful file to the DONE directory
delete_on_success="DONT"

# REPEAT DELAY
# Repeat time interval in seconds for checking the watch folder
# Minimum is 1 second, e.g. for 10 seconds, repeat_delay="10"
repeat_delay="2"

# VERBOSITY LEVEL
# Set the verbosity of the command output
# verbosity="0" is silent after banner and loading the conf file
# "3" for maximum messages
verbosity="3"

# DOCUMENT SIZE LIMIT - FUTURE DEVELOPMENT
# Number of document entries, limit for a single attribute file
doc_size="1000"

# ENFORCE TITLE CHECK - FUTURE DEVELOPMENT
enforce_title="ON"
    
# DUPLICATE PROCESS CHECK - FUTURE DEVELOPMENT
# Multiple instances of this program can be run BUT
# these would need different parameters i.e. .conf files
# Normally only one instance should run.  nameofprocess*.pl files are checked for
# If already running, a second instance can be prevented
# On Linux this check uses 'ps', on Windows, 'tasklist' could used (these must be present)
# allow_multiprocess="NO" or "YES"
# Any setting other than YES will prevent duplicate processes.
# This may cause issues if other identically named files/process are present.
allow_multiprocess="NO"
    
# RETRY - FUTURE DEVELOPMENT
# Retry any files in error that have moved to ERROR DIRECTORY
# If retry="ON" then on every swirl repeat, these move back to watch folder
retry="ON"
    
TAG

# open ddc.conf for writing
if ( !open my $DDC_CONF, '>', 'ddc.conf' ) {
    print "\n  ddc.conf would not open for reading \n";
}
else {
    print "\n Writing defaut ddc.conf\n";
 print $DDC_CONF "$conf";
 
    close $DDC_CONF or carp "Unable to close ddc.conf";
}
return;


}

## SUB TO READ THE CONF FILE ##

sub read_conf {
    my $qcount = 0
    ; # quote count - if there is less than 2 quotes then the conf line is in error
    my $quoted_var
    ;    # actual value matched from within the outer quotes " quoted var "
    while (<$CONF>) {
        # chomp; only removes current input record separator
        # and this fails to strip return character if conf file originated from Windows so:
        $_ =~ s/\r?\n$//;
        next if (/^\s*\#/xms) || ( !/=/xms );
            my ( $key, $var ) = split /=/xms, $_, 2
            ; # Optionally, white space either side of the =, limit to 2 matches, with split /\s*=\s*/xms, $_, 2
        # check that the string contains at least 2 X double quotes, store result in $qcount
        $qcount = () = m/\"/gxsm
        ;    # my $qcount = () = /.../g, counts the number of matches of $_
        # @matches = /.../g holds matches but replace with () and evaluate all in scalar context: my $count = (() = /.../g);
        # outer brackets are not requires so just to count the number of matches of " becomes $qcount = () = m/\"/g;
        
        #  print "Quote count = $qcount\n"; # Enable for debug
        if ( $qcount lt '2' ) {
            die
            "Configuration file variables should all be within double quotes, $conf_file file is invalid\nCheck and correct $key=$var\n";
        }
        ( undef, $quoted_var, undef ) = $var =~ /([^\"]*\"?)(.*)(\"[^\"]*$)/xms;
        
        # $var = $2;     $2 should contain .*, the match between outer quotes but critic does not like use of $2 outside conditional
        
        # print "key is $key, var is $var, left of quote is $1, right of quote is $3\n"; # enable for debug
        $config{$key} =
        $quoted_var;    # create a config hash, key is $key, var is $var
        
        # An alternative to the regex /([^\"]*\"?)(.*)(\"[^\"]*$)/ and taking $2
        # is to # $var =~ s/[^\"]*\"?//xms to removes anything before up to and including the first " only
        # and $var =~ s/\"[^\"]*$//xms to remove end double quote and anything after
        
    }
    return;
}    # End of sub read_conf


### THE PROGRAM ###

# Display welcome message

exit 2
if !print q{-} x '58'
  . "\n ddc_read $VERSION, run with -c to create default conf file\n"
  . q{-} x '58'
  ."\n";
  

my $option = shift @ARGV || '1';
# if @ARGV undef then || 1 is true and $option is 1 and not undef 
# prevents 'Use of uninitialized value'

# CHECK FOR -c continue switch
if ( ( $option eq '-c' ) ) { &create_conf;}

# Read $conf_file as key=value pairs, check expected parameters present
get_conf();


## CHEKC VALIDITY OF FILES AND PATHS

sub check_file_params {

# Check expected values in conf file are defined or die with helpful message
    if ( !defined $config{user_name} ) {
        die
"user_name= \"username \" not defined in conf file\n$conf_file is invalid\n";
    }
    if ( !defined $config{ddc_dbname} ) {
        die
"ddc_dbname=\"database_name\" not defined in conf file\n$conf_file is invalid\n";
    }
return;
}

## CHECK VALIDITY OF WATCH FOLDER
sub check_dirs {

    # check watch_folder

    my $trailing_check = substr $config{watch_folder}, '-1', 1
      ; # -1 (the substr offset to go back one char) is not an allowed literal value (for critic) so needs to be quoted
    if ( $trailing_check ne q{\\} && $trailing_check ne q{/} ) {
        die
"watch folder directory paths not defined correctly with trailing slash\n";
    }
}
## THE PROGRAM


print Dumper( \%config );        # Dump the config hash for debug

# perform checks

check_file_params;
check_dirs;

    


