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

# use diagnostics;      # Enable for debug
use Data::Dumper;     # Enable for debug
# use Regexp::Debugger; # Enable for debug

our $VERSION = '0.0.01';    # Version number of this script

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
  if !print q{-} x '33'
  . "\n ddc_read $VERSION\n"
  . q{-} x '33'
  . "\nLoading $conf_file...\n";

# Read $conf_file as key=value pairs, check expected parameters present
get_conf();

print Dumper( \%config );        # Dump the config hash for debug


