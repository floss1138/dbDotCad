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

# use JSON for encode_json, decode_json
use JSON;

# required for xlsx creation
use Excel::Writer::XLSX;

# use Sys::Hostname;
use feature qw(say switch state);

# use diagnostics;      # Enable for debug
use Data::Dumper;    # Enable for debug

# use Regexp::Debugger; # Enable for debug

our $VERSION = '0.0.28';    # Version number of this script

##  DEFINE FILENAMES FOR CONF AND LOG FILES HERE ##

# File name of conf file (assumed to be in same path as perl script)
my $conf_file = 'ddc.conf';

#### DONT MESS WITH VARIABLES BELOW THIS LINE - these are fixed ####

my $CONF;                   # File handle for conf file
my $EMPTY    = q{}; # Empty string the Critic way
my %config   = ();  # initialise hash to hold config
my @matches  = ();  # Array to hold regex patterns used to match candidate files
my @primkeys = ();  # initialise array to hold primary keys for block attributes
our %attributes = ();    # Empty has to hold attributes (AutoKad Metadata)

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
"\n   $conf_file cannot be read, this file must exist for the program to run!\n   $conf_file should be in the same directory as the program script\n   Check the file exists and is not currently open in some other program\n   Default config file can be created by running as:  ddc_read -c \n";
    read_conf();
    close $CONF or carp "Unable to close $conf_file\n";

   # Check paramaters in conf file match those expected
   #    conf_file_params();    # Check expected conf file parameters are present
   #    conf_folder_params();
   #    conf_behaviour_params();

    return;
}

## SUB TO CREATE A DEFAULT CONF FILE ##

# This config is intended to be for each user

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
ddc_dbname="BLOCKS"

# dbDotCad collections suffix for block attributes
# Site and possibly area code will be added, e.g. 1-02-blocks
block_collection="blocks"

# CONNECTION DB NAME
# Connectivity database name if db not on localhost (future use)
ddc_connections="ddc_con"


## DIRECTORIES - THESE MUST EXIST AND BE WITHIN THE USERS HOME DIRECTORY ##

# WATCH FOLDER
# This is the folder searched for files to be processed
# Must be defined ending in a slash to signify a folder and not a file
# watch_folder="/home/user/" # or "./" for current directory
watch_folder="/home/alice/dbdotcad/attout_to_db/"

# DONE DIRECTORY
# The folder used to hold local files after transfer if not deleted
# Must be defined ending in a slash to signify a folder and not a file
# done_dir="/home/user/done/"
done_dir="/home/alice/dbdotcad/done/"

# RETRUN DIRECTORY
# Folder to hold attribute files for loading back into CAD application
# Must be defined ending in a slash to signify a folder
# e.g. /home/alice/dbdotcad/attin/
ret_dir="/home/alice/dbdotcad/attin/"

# EXCEL DIRECTORY 
# Folder to hold xlsx files, must end in a slash to signify a folder
# e.g. /home/alice/dbdotcad/xlsx/
excel_dir="/home/alice/dbdotcad/xlsx/"

# FAILED DIRECTORY
# Folder used to hold attribute files if these have failed during processing
# error_dir="/home/user/failed/"
error_dir="/home/alice/dbdotcad/failed/"

# LOG DIRECTORY
# Folder used to hold log files
# Must be defined ending in a slash to signify a folder and not a file
# log_dir="/home/user/log/"
log_dir="/var/www/ddclog/"i

## WIRING SCHEDULE CREATION ##
# There are 3 groups for schedule spread sheets
# Common, Source, Destination
# Enter column tag or other name in presentation order, left to right
# If there is no matching tag data, the column will be blank
# As a convention, names with lower case characters are not tags.
# SCHEDULE COMMON GROUP
sched_common="NUM, CBLTYPE, CBLCOLOR, BOOT, Length,  Cut"
# SCHEDULE SOURCE GROUP
sched_src="LOCATION, SYSN, PIN, FROMTO, CONTYPE"
# SCHEDULE DESTINATION GROUP
sched_dst="LOCATION, SYSN, PIN, FROMTO, CONTYPE, Comments"
 
## NAME MAPPING ## future use

# SOURCE CPS, TO DESTINATION CPD NAMES
# Space deliminated list or source blocks and corresponding destination blocks
src_block="PINAR Net1G-CPSV1"
dst_block="PINAL Net1G-CPDV1"

## BEHAVIOURS ##
    
# ATTRIBUTE FILE NAME, PATTERN MATCH CHECK
# Pattern matches required to identify file name for transfer
# Use perl regex format. This is a regex not a glob. Check it works with rxrx.
# e.g to match the numeric part of string '1-123-45-6789-MAD_just a test_file.txt'
# fname_match1="^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*(\.txt|\.TXT)" (N-N-N-A_anYthinG.txt)
# fname_match2="^[st]\d+-([0-9]+-){3}[A-Z]+_.*(\.txt|\.TXT)" (t1-N-N-N-A_anYthinG.txt)
# s1 is for site 1, t1 is for template 1
fname_match1="^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*(\.txt|\.TXT)"
fname_match2="^[st]\d+_([0-9]+-){3}[A-Z]+_.*(\.txt|\.TXT)"
fname_match3="UNDEFINED"

# DOCUMENT TITLE
# Pattern match for the docuemnt title.  This will be used to check the document title
# If the file name is used to provide title information, this match filters the title part
# from the whole file name.  This is a bracketed regex intended to return the match in $1
# s1 is used for site 1, t1 is ued for template 1 (global tables for verification checks)
doc_title="(^[st]\d+_[0-9]+-[0-9]+-[0-9]+)"

# PREFIX FIX for fname_match1 (adds missing site code)
# The first match can be corrected to meet fname_match2 on next iteration by adding a prefix
# This is an edge case for legacy drawing numbers with insufficient number groups
# e.g. prefixfix="s1_" or x1 for cross site 1
#  The file will be renamed and meet fname_match2 on the next run
# This is only applied to fname_match1, used to identify the legacy pattern
# Set this to UNDEFINED if not used
prefixfix="s1_"

# DB COLLECTION PREFIX
# Collection prefix is intended to be site (and possibly area) code. e.g. s1_20
# Taken from the drawing title with the following match
# Note that collections names should not begin with numbers or contain hyphens - ah!a
# collection prefix is extracted from the document title - script will bail if not matching
# collection_pfix="([1-9][0-9]*-\d+)"
collection_pfix="([st]\d+_\d+)"

# FILE TRANSFER ORDER
# When more than one matching file is found, these can be sorted & sent by mtime
# File to go first:  OLD or NEW (old is default if NEW not specified)
sort_order="OLD"

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
# Retry any files in error that have moved to ERROR DIRECTORY - for debug
# If retry="ON" then on every repeat, these move back to watch folder
retry="OFF"

# ----- Attribute key names alias ----

# HANDLE is mandatory for .dxf
HANDLE="HANDLE"
TITLE="TILTE"
    

TAG

    # open ddc.conf for writing
    if ( !open my $DDC_CONF, '>', 'ddc.conf' ) {
        print "\n  ddc.conf would not open for writing \n";
    }
    else {
        print "\n Writing default ddc.conf\n";
        print $DDC_CONF "$conf";

        close $DDC_CONF or carp "Unable to close ddc.conf";
    }

    print " ddc.conf created in current directory\n\n";
    exit 0;

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
  if !print q{-} x '68'
  . "\n ddc_read $VERSION, run with -c to create default conf file then exit\n"
  . q{-} x '68' . "\n";

my $option = shift @ARGV || '1';

# if @ARGV undef then || 1 is true and $option is 1 and not undef
# prevents 'Use of uninitialized value'

# CHECK FOR -c continue switch then create the conf file
if ( ( $option eq '-c' ) ) { &create_conf; }

# Read $conf_file as key=value pairs, check expected parameters present
get_conf();

## CHEKC VALIDITY OF FILES AND PATHS

sub check_file_params {

    # Check expected values in conf file are defined or die with helpful message
    # This can be done specifically ...
    if ( $config{user_name} eq $EMPTY ) {
        die
"user_name= \"username \" not defined in conf file\n$conf_file is invalid\n";
    }
    if ( $config{ddc_dbname} eq $EMPTY ) {
        die
"ddc_dbname=\"database_name\" not defined in conf file\n$conf_file is invalid\n";
    }

    # or more generally, iterate over the hash looking for undefined items ...

    for my $cfgitem ( keys %config ) {

        # Print config item for debug:
        # print "checking config for $cfgitem\n";
        if ( $config{$cfgitem} eq $EMPTY ) {
            die
" $cfgitem was not defined in conf file \n $conf_file is invalid, script is terminated\n";
        }
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

## WATCHFOLDER SUBROUTINE  Returns array of files found ##
# Takes watch folder name as input
# Matches file names based on @matches regex from conf file
# Return array of matching file names found

sub read_watch_folder {
    my ($watch_folder) = @_;
    my @candidates     = (); # Variable to hold time sorted, matching file names
    my @total          = (); # array to hold total file names matching
    my $time = time_check(); # check the current time
                             # print "\nSearching $watch_folder at $time\n";

    foreach (@matches) {
        opendir( DIR, $watch_folder )
          || croak "can't opendir $watch_folder - program will terminate";
        my $match = $_;

       #  print "\n Looking in $watch_folder\n";
       #  print "\n matching with > $match\n";
       #  print "\n First match regex is $matches[0]\n";
       # Cannot use $_ within readdir for next match so assigned to a $match var
       # It is possible sort { -M ($watch_folder.$b) <=> -M ($watch_folder.$a) }

        @candidates =
          grep { !/^\./ && -f "$watch_folder/$_" && (/$match/xms) }
          readdir(DIR);

# Prefix fix.  Fix is applied by adding prefix value to legacy file name found in 1st match ONLY
        foreach (@candidates) {

            print "Candidate file name: $_\n";
            if ( /$matches[0]/xms && ( $config{prefixfix} ne 'UNDEFINED' ) ) {

  #    print "\n Legacy file name found \n Needs to be $config{prefixfix}$_ \n";
                rename "$config{watch_folder}$_",
                  "$config{watch_folder}$config{prefixfix}$_";
            }

        }
        push @total, @candidates;
    }

    return @total;
}

## LOCKTEST SUBROUTINE ##
# Confirm if a file exists and is open/not locked
# If it does exit try an open for append & read, if "denied" report locked, otherwise report open

# Return 0 if file found and can be opened/closed
# Return 1 if file locked
# Return 2 if file not found
# carp if it will not close

sub locktest {

    # Potentially growing filename passed to $fname
    my ($fname) = @_
      ; # Becasue Perl:Critic does not like my $fname = shift @_; for each element, rather my ($element1 $element2) = @_;

# APPEND will create the file if it does not exist so check with -f if filename is present before append test
# APPEND may be safer than just opening for writing.  + also opens for read
    if ( -f $fname ) {

#Perl Critic requires an error trap for open such as carp.  Trapping this after open with if ($!) is not good enough
#If you don't want warn or carp sending output for !open, use the following:
        if ( !open my $HANDLE, '+>>', $fname ) {
            return 1;
        }
        else {
            close $HANDLE or carp "Unable to close '$fname'";
            return 0;
        }    # if wont !open retrun 1, open return 0

    }    # if -f $fname
    else {

        # print "\n$fname not found \n";
        return '2';
    }
    return
      '3'
      ; # End of sub return - should not be reached, return as if file cannot be found/opened

}

## STAT AND SEEK SUBROUTINE ##

# Confirm if the file exists and can be read
# Return stat (byte count and mtime) with seek value if file exists and can be opened
# Check the last $bytes and append onto this the file size with mtime
# Return string looks like this: <cnseek_return>last_$last_bytes_of_file_end$bcount$mtime</cnseek_return>
# Return 1 if file cannot be opened for read
# Return 2 if file not found

# seek is used to set pointer to last $bytes from end of file, 2 is end, 1 is beginning 0 is current position

sub statnseek {
    my ($seekname) = @_;
    my $bytes = '20';  # constant - number of bytes to read/check at end of file

    my $seek_open_tag =
      '<cnseek_return>';    # xml style tag for count and seek string
    my $seek_close_tag = '</cnseek_return>';    # xml close tag
    my $file_end;    # variable to hold last $bytes of file
    if ( -f $seekname ) {

        if ( !open my $HANDLE, '<', $seekname ) {
            print1("$seekname cannot be read\n");
            return 1;
        }
        else {

            seek $HANDLE, -$bytes, 2
              ; # number of bytes needs to be -negative -$bytes as seek counts from the end if next argument is 2
            sysread $HANDLE, $file_end, $bytes;
            close $HANDLE or carp "Unable to close '$seekname'";

            # read $bytes of file from pointer position
            # my $bcount = -s $seekname; # now using stat size

            my $stats  = stat $seekname;
            my $bcount = $stats->size;
            my $mtime  = $stats->mtime;
            my $cnseek =
              $seek_open_tag . $file_end . $bcount . $mtime . $seek_close_tag;

# print "File end text $cnseek\n"; # enable for debug, print stat and seek value
            return $cnseek;

        }

    }

    else {
        print1("$seekname not found\n ");
        return 2;
    }

    return
      1
      ; # End of count & seek sub, return should not be reached, error as if file cannot be opened

}

# Sub to read (first)  HANDEL line in attout and return keys:
# Take filename (with path) as argument
# Confirm attout format by checking first line starts with HANDEL
# Return array of Key names

# array @keys to hold attribute tag keys in CAD required order
my @keys = ();

sub readHANDLEline {
    my ($att_file_name) = @_;

    # array @keys to hold attribute tag keys in CAD required order
    my @keys = ();

    #  print "\n   Attribute file name = $att_file_name\n";
    if ( !open my $ATTOUT, '<', $att_file_name ) {
        print "\n   failed to open $att_file_name\n";
    }
    else {
        my $line;

        # take first line only into $line
        $line = <$ATTOUT>;
        if ( !defined($line) ) {
            print "\n  $att_file_name seems empty or contents undefined\n";
            return 0;
        }

# chomp($line), but chomp was failing to remove trailing return from last key, could try paragraph mode where $/ = ''
        $line =~ s/\rr?\n$//;

        # print "\n line contains $line\n";

        if ( $line =~ /^HANDLE/xsm ) {
            print "\n   $att_file_name is valid\n";

            # remove line breaks
            $line =~ s/\r?\n$//;

            # alternative to $/ = "\r\n"; for both Linux and Windows

            # split on tab
            @keys = split( /\t/, $line );

            # chomp(@keys); already chommped $line above
            #   foreach my $heading (@keys) {
            #  print "\n  $heading\n";}
            return (@keys);
        }
        else {
            print "\n   $att_file_name does not look like an attribute file\n";
            return 1;
        }
        close($ATTOUT);
    }

    #end of reading HANDEL line routine
    print "\n read HANDEL line is over! This line should not be reached \n";
}

# End of readHANDELline sub

## SUB TO CREATE MONGODB QUEREY
# Takes path with filename, database name, collection name, and ref to primary key array as arguments
sub makequerey {
    my ( $qfile, $dbname, $coll, $prims ) = @_;

    # deref array
    my @primarray = @$prims;
    my $quereyh = " // block querey // \n\ndb = db.getSiblingDB('$dbname')\;\n";

    # open querey file for writing
    if ( !open my $QUEREY, '>', "$qfile" ) {
        print "\n  querey file $qfile would not open for writing \n";
    }
    else {
        # print "\n Writing header \n $quereyh \n to querey file $qfile\n";
        print $QUEREY "$quereyh";
        foreach (@primarray) {

    # If output required is block per line, dont printjson
    # print $QUEREY "db.$coll.find ({\"_id\" : \"$_\"}).forEach(printjson)\;\n";
            print $QUEREY "db.$coll.find ({\"_id\" : \"$_\"})\;\n";
        }

        close $QUEREY or carp "Unable to close $qfile file";
    }
    return 0;
}

# End of makequerey sub
my %block_id;

#  hash to hold block identification using attribute tag string as key,
# ORIGINAL block name as value that can be UPDATED if duplicated.  Updated names have update number in brackets e.g. NAME(3)

# pass %block_id to Excel routing and make it Excel worksheet safe
# as %block_id_excel

## SUB TO CREATE ATTIN FILE AND EXCEL SHEET FROM MONGO QUEREY
# Takes filename with path (of json querey result) and turns this into attin.txt for CAD
# First argument is json filename with path, then the \@keys (column headings) required (in order) by CAD
# Blocknames are required to create spreadsheet (for each tab), third argument is \@blocks
sub attin {
    my $attin_string;

# If blockname value found with different attribute tag string, change existing from NAME to NAME(1) for use in spread sheets only.
# Next NAME instance cleash becomes NAME(2) etc
# This edge case should only occure if blocks are pasted in from another drawing
# Best practice is to always put a version number in the block name, even if only the attribute order is changed.
    my ( $finname, $columns, $blocknames ) = @_;

    # deref array holding column titles
    my @keys = @$columns;


# print Dumper \$blocknames;

    # my $attfile = "$config{ret_dir}.basename($finname)";
    my $attfile = $config{ret_dir} . basename($finname);
    $attfile =~ s/\.json/\.txt/;
    print
"\nAttin is using $finname, which requires column headings: \n@keys\nand will create $attfile\n";
    foreach (@keys) {
        $attin_string .= "$_\t";
    }

# This created column headings followed by a tab, so remove last tab and replace with Windows line end
    $attin_string =~ s/\t$/\r\n/;

    #      print "$attin_string<-----\n";

    if ( !open my $JSONIN, '<', $finname ) {
        print "\n $finname would not open for reading\n";
    }
    else {
# remove 1st element of keys (which should be HANDEL) and build line by key value
        my $first = shift @keys;

        #     print "\n first element of keys was $first\n";

     # Counter for block names clashes used to de duplicate repeated block names
        my $name_clash = 0;

        while (<$JSONIN>) {
            if (/^{\s*"_id"\s*:\s*"'/) {

                # if it looks like its a json line { "_id" : "' then process it

                my $line = decode_json($_);

                #  print $line->{'_id'} . " is the primary key\n";
                my $pkey = $line->{'_id'};
                $pkey =~ /('[0-9A-F]+)/;

                #  print "\npkey is $pkey, HANDEL is $1 \n";
                my $bname = $line->{'BLOCKNAME'};
                my @block;

               # Enable for debug
               # print "BLOCKNAME in attin-string is $bname\n";
                # build attin_string starting with the handel
                $attin_string .= $1;

  # for remaining keys, i.e. column headings add a tab then the value of the key
                foreach (@keys) {
                    my $next = $line->{$_};
                    if ( defined $next ) {

                        # print "$bname uses $_\n";
                        push @block, "$_";
                    }

# If undefined then CAD data had no value for this key and attout packs (no) value with <>, //= is the assignment opertor of // logical defined-or operator
                    $next //= '<>';

                    #   print "\n key is $_, value is $next\n";
                    $attin_string .= "\t$next";
                }
                $attin_string .= "\r\n";

# It is possible to duplicate a blockname with different attributes (by pasting a block into a drawing which has an existing block name.  The handel will be chaged but different attribute tags may have been imported).
# duplicates may appear with different columns
#   print "BLOCKNAME is $bname, contains @block \n";
# my $block_ident = $bname;
                my $block_ident;

# create block_ident identifying attribute tag string ,$blockname,COL1,COL2,COL3 (COL1 will be BLOCKNAME)
# This ,blockname,attribute_tag1,attribute_tag2,etc (in order) will identify duplicated block names
                unshift @block, ($bname);
                foreach my $column (@block) {

# A block name with a leading or trailing space will be treated as a different name so trim spaces
#As attin is dealing with database content it should be clean unless manually edited
                    $column =~ s/^\s+|\s+$//g;
                    $block_ident .= ",$column";
                    $block[0] =~ s/^\s+|\s+$//g;

                    # also performed on block[0] just to be safe
                }

# print "block ident is tag string: $block_ident\n";
# if ( exists $block_id{$block_ident}){
# print "block_ident has been seen before for $block[0], this one got there first and should not be duplicated \n";
# }
                if ( not exists $block_id{$block_ident} ) {

                    # Write value against attribute tab ident for first instance
                    # Then, change the blockname value if there is a clash

                    $block_id{$block_ident} = $block[0];
# First instance of a particular block ident - print for debug                  
#  print"    First sighting of block ident $block_ident\n    This has been set to blockname: $block[0]\n";
                }

# There will always be one allowable instance - if more than 1, its best to sort by key for consitency.
# Two men say they are Jesus, at least one of them must be wrong
                foreach ( sort keys %block_id ) {

                    if ( $block[0] eq $block_id{$_} ) {

# if its the current tag string skip, rename the other based on name clash count
                        next if ( $_ eq $block_ident );
                        $name_clash++;
                        if ( $name_clash > 0 ) {
#  Block name clash found, print for debug
#  print "$block_id{$_} value already exists in $_\nas a block name and needs to be changed to $block_id{$_}$name_clash\n";

                            $block_id{$_} = $block_id{$_} . "($name_clash)";
                        }
                    }

                }

                # print "\n attin is \n$attin_string\n";
                #  print "key: $_\n" for keys %{$line};
                #  print Dumper($line);
            }

            # end of if valid JSON line

        }

        # end of while JSONIN

        print "Blockname clashes =  $name_clash\n";

        # end of while JSONIN

# enable for debug to see duplicate blocknames with different keys here:
#    print "\n block_id hash contains attribute tag string as hash and blockname as key\n";
#    print Dumper ( \%block_id );

# foreach my $key_ident ( sort keys %block_id ) {
#  print "block names for unique attribute tag string: $block_id{$key_ident}\n";
# }
        # For debug print all blocknames for attribute tag string
      #  foreach my $unique_value ( sort values %block_id ) {
       #     print "blocknames for unique attribtue tag string: $unique_value\n";
       # }

# worksheet needs to be identified by using %block_id key and looking up the value

        # Print attin file for debug
        # print "\n attin_string is \n$attin_string\n";

        # print $attin_string to a file attin.txt
        # open attin file for writing
        if ( !open my $ATTIN, '>', $attfile ) {
            print "\n  $attfile would not open for writing \n";
        }
        else {
            print "Writing attin file $attfile ...\n";
            print $ATTIN "$attin_string";

            close $ATTIN or carp "Unable to close $attfile file";
        }

        close $JSONIN or carp "could not close $finname/";
    }    # End of else JSONIN

}

## Create Excel sub
# A \ IN THE BLOCK NAME OR VALUE DATA IS BEING REMOVED WHEN PRINTED/DUMPED
# so \\ becomes \, its perl delimiting thats to blame.  Print may be differ from Dump. 
# Take filename, attribute tags and block_id as arguments
sub excel {

    # $row is the first row number for attribute data
    my $row = '5';
    my ( $finname, $att_tags, $blocknames ) = @_;
    # deref block_id hash to create a worksheet save naming version
    my %block_id_excel = %$blocknames;
   # print "block id hash passed to excel sub is:\n";
   # print Dumper (\$blocknames);
    # same thing but the order will vary... 
    # print Dumper (\%block_id_excel);
   
   # foreach my $wsname (values %block_id_excel) {
    #    if ($wsname =~ m/[\*\:\[\]\?\\\/]/xsm) { 
     #   print "$wsname  contains a worksheet prohibited character []*:?/\\ \n";
 #       }
  #  }


        foreach my $k (keys %block_id_excel) {
        # substitute  []*:?/\ with ~
        # $block_id_excel{$k} =~ s/[\*\:\[\]\?\\\/]/~/g;
        # Translate []:*?/\ to {}.#!><
          $block_id_excel{$k} =~ tr/[]:*?\/\\/{}.#!></;
        }

# print "Excel safe sheet names should only exist now:\n";
#  print Dumper (\%block_id_excel);
    #de-ref attribute tags (keys) into @keys
    my @keys = @$att_tags;

    my $xlsxout = $config{excel_dir} . basename($finname);
    $xlsxout =~ s/\.json/\.xlsx/;
    print "\nxlsx output file will be called $xlsxout \n";

    my $workbook = Excel::Writer::XLSX->new("$xlsxout");

    $workbook->set_properties(
        title  => 'CAD attribute data',
        author => 'DeeV',
        comments =>
'Support cross platform Open Source solutions.  Respect CC & GPL Licenses',
    );    # This might not be visible from Open Office

    my $worksheet_rm = $workbook->add_worksheet('Readme');

    #Format Worksheet readme tab:
    my $time = time_check();
    $worksheet_rm->write( 'B2', "Created by ddc reader $VERSION at $time" )
      ;    #  worksheet created for info, notices & copyright
    $worksheet_rm->write( 'B3',
"This software is copyright (c) 2017 by Floss (floss1138\@gmail.com) - a dolphin friendly PDP project.  All rights reserved."
    );
    $worksheet_rm->write( 'B4',
"You are free to use, copy and distribute this software under the same GPL terms as the Perl 5 programming language."
    );
    $worksheet_rm->write( 'B7', 'Notes:' );
    $worksheet_rm->write( 'B8', 'This spreadsheet is the result of a database query.  To meet spreadsheet naming convention, some names may have been changed:' );
    $worksheet_rm->write( 'B9',
'Worksheet names cannot contain []:*?/\ characters but block names can. If found, these are translated as {}.#!><.'
    );
    $worksheet_rm->write( 'B11',
'Blocks with different attributes but the same name can be duplicated by copying between drawings.');
    $worksheet_rm->write( 'B10', 'Hopefully you have a strict block naming policy which enforces use of a version number, prohibits strange characters including those above and limits the the block name to 30 characters.'
    );
    $worksheet_rm->write( 'B12',
'Duplicated block names, for example those with different attribute tags but all called NAME, will be renamed in the worksheet tab only as NAME(1), NAME(2) etc.'
    );
    $worksheet_rm->write( 'B14',
'The first row and column are margins for notes');
    $worksheet_rm->write( 'B15', 'Columns B & C containing the Mongo _id & untranslated block name are intentionally hidden'
    );

# Hash to hold value count used to track which row of which sheet to be updated, starting at row $row
    my %unique_value_count;
    print "Unique value is: ";
    foreach my $unique_value ( sort values %block_id_excel ) {
        print "$unique_value ";
        $unique_value_count{$unique_value} = $row;

        my $worksheet = $workbook->add_worksheet("$unique_value");
        $worksheet->write( 'A2',
            "Worksheet for $unique_value blocks, created on $time" );
    }
    print "\n";

# print Dumper ( \%unique_value_count );
# worksheet needs to be identified by using %block_id key and looking up the value

    if ( !open my $JSONIN, '<', $finname ) {
        print "\n $finname would not open for reading\n";
    }
    else {
# remove 1st element of keys (which should be HANDEL) and build line by key value
# my $first = shift @keys;

        while (<$JSONIN>) {
            if (/^{\s*"_id"\s*:\s*"'/) {

                # if it looks like its a json line { "_id" : "' then process it

                my $line = decode_json($_);
                my %linehash = %$line;
       #      foreach (sort keys %linehash) { print "linehash contains, key: $_ value: $linehash{$_}\n";}
   #           print "   JSON decode line (check the slash content) of $line->{'BLOCKNAME'}:\n";

  #            print Dumper (\$line);
           # apparenly you can use keys direcly on a hash ref after 5.14
           # For debug print the hash - its not in order so use keys to preserve
           # CAD order and add any internal fields which need to be visible
           #print "\n json values are:\n\n";
           #foreach my $val (values $line) {
           #print "$val\n";
           # }

                my $bname = $line->{'BLOCKNAME'};
                my @block;
                # print "BLOCKNAME in excel-string is $bname\n";
                # use keys to re-create block_id

# TRY TO DO THIS WITHOUT TAKING KEYs as argument, just use the JSON
# The database has additional keys to the CAD attributes.
# A leading underscore convention has been used to match mongos field names
# _id is the primary key, _whatever is used for fields which we may want in a spread sheet.  There could be a naming clash as CAD will allow a leading underscore so reference is made to the original CAD keys as a filter
# for remaining keys, i.e. column headings add a tab then the value of the key
                foreach (@keys) {
                    my $next = $line->{$_};
                    if ( defined $next ) {

                        # print "$bname uses $_\n";
                        push @block, "$_";
                    }
                }

# print the keys and value.  $line is a ref to the hash created by json decode with print "Key is $k, value ". $line->{$k} ."\n";

# Testing if the key exists in the CAD tags is the same as seeing if the @keys is defined but this does not have correct order:
#foreach my $k ( keys %$line ) {
# print "Key is $k, value ". $line->{$k} ."\n";
# if ($k ~~ @keys) {
# print "$k is a CAD tag\n";
#    push @block, "$k";
# Look up this key to see if a duplicate blockname was previously identified
# print "key is $k, value is $line->{$k} \n";
#    }
#}

                my $block_ident;

# create block_ident identifying attribute tag string ,$blockname,COL1,COL2,COL3 (COL1 will be BLOCKNAME)
# This ,blockname,attribute_tag1,attribute_tag2,etc (in order) will identify duplicated block names - unshift adds blockname to @block as first element
                unshift @block, ($bname);
                foreach my $column (@block) {

# A block name with a leading or trailing space will be treated as a different name so trim spaces
#As attin is dealing with database content it should be clean unless manually edited
                    $column =~ s/^\s+|\s+$//g;
                    $block_ident .= ",$column";
                    $block[0] =~ s/^\s+|\s+$//g;

                    # also performed on block[0] just to be safe
                }    # end of foreach block

                # print "block_ident for excel is $block_ident\n";
                # see if this checks out in %block_id here ..
                # print Dumper ( \%block_id );
                # Current worksheet name at this point in loop is:
                my $worksheet_name = $block_id_excel{$block_ident};
#  print "Value for this tag string is the worksheet_name: $block_id_excel{$block_ident} \n and must only contain valid sheet names \n";

               # WRITE block_ident into Excel as a test.  Current hash ref to sheet $worksheet_name is $current_sheet, enable these lines for testing:
                my $current_sheet =
                  $workbook->get_worksheet_by_name($worksheet_name);

               # For Excel intital write testing, just write the block_ident to current sheet here:
               # $current_sheet->write( "C3", $block_ident );

               # $current_sheet->write( "C$unique_value_count{$worksheet_name}",
               #     $block_ident );

   # $current_sheet->write ( "C$unique_value_count{$worksheet_name}", linedata);
   # Row number is $unique_value_count{$worksheet_name}
   # Column letter could use some form of iterator.  Lets limit this to 52 as a spread sheet bigger than that is going to be painful
   # That becomes A to AZ, create this range in an array @alph

                my @alph = ('A'..'Z', 'AA'..'AZ');
                # format1 to make heading bold and background yellow
                my $format1 = $workbook->add_format( bold => 1, bg_color => 'yellow' ); # color => is the font color

                # Remove first element of array as the linehash does not contain HANDEL, thats part of the _id.  
                # Will need to add any DB fields required in the spread sheet to array col, in the required order here: 
                my @col = @keys;
           # strip first element (HANDEL)
           my $first = shift @col;
           # replace with _id at beginning of array
           unshift @col, '_id';
           push @col, '_title', '_filename', '_errancy';
                # alpha_offset allows for blank column(s) at the left of the spread sheet, like the row offfset allows for blank lines at the top
                my $alph_offset = '1';
                my $headline = $row-1;
# print "headline is set to $headline\n";
                    # Write column names to spread sheet
                    # Format head line as format1,  $headline-1 required as set_row starts from 0 
                    $current_sheet->set_row( $headline-1 , undef, $format1 );

# Set column width - before hiding as it seems to override
$current_sheet->set_column('C:AZ', 14);
# _id needs a wider column even if it is hidden
 $current_sheet->set_column('B:B', 18); 

# Hide B column which contains the _id
$current_sheet->set_column( 'B:C' , undef , undef,  1, 0, 0 ); 	# This hides column B to C which is the _id and BLOCKNAME.  Blockname shoul be teh same on every line.
# Set column width
# $current_sheet->set_column('C:AZ', 15);	
# print "headline after setting the format is $headline\n";
                    foreach(@col) {
                    $current_sheet->write ("$alph[$alph_offset]$headline" , $_);
                    $alph_offset ++;
                    }
                    $alph_offset = '1';
                    foreach (@col) { 
                    # print "linehash columns for excel with offsets; key (col name): $_ value: $linehash{$_}, alpha offset: $alph_offset increments to column: $alph[$alph_offset]\n";
                    # write line to Excel
                     $current_sheet->write ("$alph[$alph_offset]$unique_value_count{$worksheet_name}" , $linehash{$_});
                    # increment alpha_offset i.e column letter
                    $alph_offset ++;
                    }
                    



                # Increment the row value, to write data at for the worksheet
                $unique_value_count{$worksheet_name}++;

# print Dumper ( \%unique_value_count );
# Insert row based on worksheet and next available row number
# my $current_worksheet = $workbook->add_worksheet($worksheet_name);
# Its necessary to rationalise blockname to match excel sheet names
# No more than 32 characters, 29 allowing for (x),
# or contain []:*?/\  and its case insensitive, CAD is uppercase only for block names
# $worksheet($worksheet_name)->write( 'C'.%unique_value_count{$worksheet_name}, $block_ident);
            }
        }
    }

# checkout get_worksheet_by_name(), $worksheet = $workbook->get_worksheet_by_name('Sheet1');
    print "Worksheets are:\n";
    for my $worksheets ( $workbook->sheets() ) {
        print $worksheets->get_name() . " ";
    }

    # my $sheet = $workbook->get_worksheet_by_name('BLOCK_NAME');
    # print "\nSheet BLOCK_NAME is called $sheet\n";
    print "\nFinal unique_value_count hash contains the count + initial row offset value:\n";
    print Dumper ( \%unique_value_count );
}
## THE PROGRAM

# print the hash for debug
# print Dumper( \%config );        # Dump the config hash for debug

# perform checks

check_file_params;
check_dirs;

##  CREATE A MATCH REGEX ARRAY @matches FROM THE CONF FILE

# matches are space separated array of file names to match on, in order of preference #

my @match_files =
  ( $config{fname_match1}, $config{fname_match2}, $config{fname_match3} );

# create list of valid match requirements based on regex from conf file

foreach (@match_files) {
    if   ( $_ eq 'UNDEFINED' ) { next; }
    else                       { push @matches, $_; }
}

# foreach (@matches) {
#   print " Using following regex for matching:\n >$_<\n";
#  }

my $user_time = time_check();
while (1) {

    # read watch folder and create an array of attribute files found:
    my @attfiles = read_watch_folder( $config{watch_folder} );

    print "\nTotal matched files >\n";
    foreach (@attfiles) {
        my $attfile = $_;

        # add the file path to the file
        my $filewithpath = $config{watch_folder} . $attfile;

        # see if its locked
        my $isitlocked = locktest($filewithpath);

        # print "$filewithpath locktest = $isitlocked\n";
        # if file is not locked, see if its growing
        if ( $isitlocked eq 0 ) {
            my $isitgrowing1 = statnseek($filewithpath);

          # print " \n$_ $isitgrowing1 is not locked check again for growing\n";
            sleep $config{growing_time};
            my $isitgrowing2 = statnseek($filewithpath);
            if ( $isitgrowing1 eq $isitgrowing2 ) {

                # print "\n not growing\n";
### process files here
                my $done_name = $config{done_dir} . $attfile;

             # read HANDEL line into array @keys from $filewithpath
             # return is zero if empty, 1 if invalid
             # The @keys array contains the tag values IN THE REQUIRED CAD ORDER
             # @keys needs to be available for the attin and excel subroutines
                my @keys = readHANDLEline($filewithpath);

                # skip if file is empty or invalid
                next if ( $keys[0] eq 0 | $keys[0] eq 1 );

                # enable for debug
                print "  \n Column headings are:\n";
                foreach my $heading_keys (@keys) {
                    print "  $heading_keys";
                }
                print "\n";

# Document TITLE is taken from the filename (or, in later version the TITLE attribute)
# Extract title based on config file regex here:
                my $doctitle = 'doc_title_is_undefined';

         #       print
"\n File name is $attfile, regex used is $config{doc_title} \n";
                $attfile =~ /$config{doc_title}/xsm;
                $doctitle = $1;

# remove leading zero from doctitle as this is used in primary key s1_02-03-2475 should become s1_2-3-2475

                print "Filename is $attfile, doctitle is $doctitle from regex $config{doc_title}\n";

# site code is the first nnumber(s) before the first - and should not have a leading 0
# site code is used to prefix the collection name and may become a site-area code in the future

   #  $doctitle =~ m/(^[1-9][0-9]*-)/;
   # match doctitle to extract site prefix (from collection_pfix in config file)
                if ( $doctitle !~ /$config{collection_pfix}/xsm ) {
                    croak
"\n collection name could not be created, check collection_prfix definition can be extracted from document title\n";
                }
                $doctitle =~ /$config{collection_pfix}/xsm;

# collection names cannot start with a number or contain a hyphen (without unpredictable delimiting)
                my $collection_prefix = $1;

   # Leading zeros may or may not exist but for collection names they are banned
   #  Remove leading zero from area or any number in a collection name here
                $collection_prefix =~ s/0+(\d+)/$1/xsm;

                #  Remove any hyphens from the collection name
                $collection_prefix =~ s/-+//xsm;

    # create collection name based on site prefix and collection name for blocks
                my $collection = $collection_prefix . $config{block_collection};

# print " \n  matching document title is >$doctitle<, site match is: $1, collection is $collection \n";

# read attribute line into array @att from $filewithpath
# deduplicate block names into %blocks hash adding block name count as the value
                my %blocks;
                my $block_count = '0';
                my %hof_blocks;
                open my $ATTOUT, "$filewithpath" or die "cannot open file: $!";
                while (<$ATTOUT>) {
                    if ( $_ =~ /^'[0-9A-F]/xsm ) {

                        # print ("\n   Valid start to attribute line: $_\n");

                        my @att = split( /\t/, $_ );    # split on tab
                           # It seems necessary to leave the newline in before the split as an empty attribute value
                           # will be missed if this is the last item in the intended array.  Chomp each value in the array
                           # after the split
                        foreach my $chomping (@att) {
                            $chomping =~ s/\r?\n$//;

                        # alternative to $/ = "\r\n"; for both Linux and Windows
                        }

                       # enable for debug
                       # print "\n Attribute line contains:\n";
                       # my $att_number = @att;
                       # print "\n $att_number attribute value(s) captured\n\n";
                       # foreach my $attributes (@att) {
                       #    print " $attributes ";
                       # }

# Create a hash of attribute arrays where $att[0] is the key.  By adding the document title matched from $attfile filename, a primary key is generated
# With new blocks the TITLE field in the block would be used.
# Create primary key by appending the HANDLE to the TITLE.  The underscore is deliberate syntax.  So is leaving in the leading ' provided by AutoKAD

                        my $pkey = "$att[0]_$doctitle";

# Document title should not contain leading zeros but if these have been inherited from a filename, better remove them to keep the primary key clean
# Remove leading zero but leave a single zero (as 0 may be an area)
# s1_00_0123_4050 becomes s1_0-123_4050
# Does not apply to the CAD HANDLE

                        $pkey =~ s/_0+(\d+)/_$1/g;
                        $pkey =~ s/-0+(\d+)/-$1/g;

                        # print "\n   primary key is $pkey\n";

# block_name = $att[1] i.e. second elemet is always the BLOCKNAME
# putting this into a hash deduplicates the blockname, value does not matter but is used as a count
# A block name with a leading or trailing space will be treated as a different name so trim spaces
                        $att[1] =~ s/^\s+|\s+$//g;

                        if ( exists $blocks{ $att[1] } ) {

                            #    print "\n $att[1] has been seen before\n";

               # if exits, increment count for that block name, else set it to 1
                            $blocks{ $att[1] }++;

                            # Write attribute array to hash of blocks
                            $hof_blocks{$pkey} = \@att;
                        }
                        else {
                            $blocks{ $att[1] } = '1';
                            $hof_blocks{$pkey} = \@att;
                        }

# Enable for debug (used here will run on each loop):
# print Dumper \%blocks;
# print Dumper \%hof_blocks;
# print array out if BLOCKNAME = test, might be better with an array of arrays to preserve HANDLE order??
# foreach my $k (sort keys %hof_blocks ) { block name with a leading or trailing space will be treated as a different name so trim spaces
                        $att[1] =~ s/^\s+|\s+$//g;

                        if ( exists $blocks{ $att[1] } ) {

                            #    print "\n $att[1] has been seen before\n";

               # if exits, increment count for that block name, else set it to 1
                            $blocks{ $att[1] }++;

                            # Write attribute array to hash of blocks
                            $hof_blocks{$pkey} = \@att;
                        }
                        else {
                            $blocks{ $att[1] } = '1';
                            $hof_blocks{$pkey} = \@att;
                        }

                        # Enable for debug (used here will run on each loop):
                        # print Dumper \%blocks;
                        # print Dumper \%hof_blocks;

                        #    foreach ( @{ $hof_blocks{$k} } ) {
                        #        print "   Block with name >test< found: $_ \n"
                        #          if ( $hof_blocks{$k}[1] =~ /test/xsm );
                        #    }
                        #    print "\n";
                        # }
                    }

                    # end of if ^'[0-9]
                }

                # end of while (<ATTOUT>)
                close($ATTOUT);

                # Dump blocks for debug
                # print "\n now dumping blocks \n";
                # print Dumper \%blocks;
                # print "\n now dumping hash of blocks \n";
                # print Dumper \%hof_blocks;
                # my $json = encode_json \%hof_blocks;
                # print "\n JSON version of hash of blocks:\n$json\n";
                my $jstring
                  ; # string to hold js script to bulk output attributes as json to mongo
                 #    print "\nvar attout = db.collection_name.initializeUnorderedBulkOp()\;\n";
                $jstring =
" // bulk BLOCK attribute import // \n\ndb = db.getSiblingDB('$config{ddc_dbname}')\;\nvar attout = db.$collection.initializeUnorderedBulkOp()\;\n";

                #  $|=1; Autoflush not necessary

#  Note that the first element [0] is the HANDLE which forms part of _id, so the actual document content starts at [1] with the BLOCKNAME
#  For each key create a line entry to be turned into a mongoDB document

                foreach ( keys %hof_blocks ) {

# Create json string beginning with mongoDB primary key, _id and document _title
# Although document _title is part of the primary key, db.ATTOUT.find({ "_id": /.*s1-02-03-04/ }) is costly
# Having a _title field allows for future indexing.  _title will also exist as an attribute in well made blocks
                    $jstring .= "attout.insert({\"_id\" : \"$_\"";

                    # Write id into primkeyis array
                    push( @primkeys, "$_" );

                    my $column_count = @keys;

                    for ( my $i = 1 ; $i < $column_count ; $i++ ) {

# Add key to string bassed on column number
# but only if the value is not <> i.e. AutoKAD attout value was empty as this key does not appear in the block
# Will throw use of uninitialised value if value of key is empty as is the case
#   if (!defined $hof_blocks{$_}[$i]){
#   print "\n Row $_, key $keys[$i] had an undefined element $i if last array element is missing \n";
#                                    }
                        if ( $hof_blocks{$_}[$i] ne '<>' ) {
                            $jstring .= ", \"$keys[$i]\" : ";

# Add element value after key based on same column number but if the value contains double quote, delimit it first
# For example '19" rack' becomes '19\" rack'
                            my $att_value = $hof_blocks{$_}[$i];
                            $att_value =~ s/\"/\\"/g;
                            $jstring .= "\"$att_value\"";
                        }
                    }

                    #  Add user name, time and terminating string

                    $jstring .=
", \"_link\" : \"NO\", \"_title\" : \"$doctitle\", \"_filename\" : \"$attfile\", \"_errancy\" : \"OK\", \"_user_time\" : \"$config{user_name} $user_time\"})\;\n";

                    # print string on each run to see it build line by line:
                    # print "\n\n$jstring\n\n";
                }

               # Add js command to execute bulk output as last line of js script
                $jstring .= "attout.execute()\;";

                # print final json bulk op string to screen for debug
                # print "\n$jstring\n";

              # Write js bulk output script to file
              #  open my $JSON, '>', '/home/alice/dbdotcad/done/mongo_attout.js'
                open my $JSON, '>', "$config{done_dir}$doctitle.attout.js"

                  or carp "Mongo js file could not be opened\n";
                exit 1 if !print {$JSON} "$jstring";
                close $JSON or carp "Unable to close Mongo js file\n";

                # Print primary keys used
                # print "\n Primary keys are:\n @primkeys\n";

# Create js file to querey database with same keys used for attout
# Use _id to also create a querey script using doctitle.attin.js as the file name
# Take pathwithfilename, dbname , ref to primkeys as arguements
                makequerey( "$config{done_dir}$doctitle.attin.js",
                    "$config{ddc_dbname}", $collection, \@primkeys );

                # Upload to DB - execute bulkop
                print "Mongo upload results will be written to: $config{done_dir}$doctitle.attout_result.txt\n";
                system(
"mongo < $config{done_dir}$doctitle.attout.js > $config{done_dir}$doctitle.attout_result.txt"
                );
                print "Mongo query results will be written to: $config{done_dir}$doctitle.attin.json\n";
                # Query database - based on same primary keys used for bulkop
                system(
"mongo < $config{done_dir}$doctitle.attin.js > $config{done_dir}$doctitle.attin.json"
                );

                # move file to done directory
                if ( rename $filewithpath, $done_name ) {
                    print "\n $filewithpath moved to:\n $done_name\n";
                }

                # call attin sub here to create attin file
                attin( "$config{done_dir}$doctitle.attin.json",
                    \@keys, \%blocks );

# create xlsx from json.  Use %block_id created during attin creation to map tag identifier to a unique name. Pass json mongo result, attribute keys arran and block_id has to sub
                excel( "$config{done_dir}$doctitle.attin.json", \@keys, \%block_id );

            }

            # End of isitgrowing
        }

        # End of foreach @attfiles
    }
# Clear block_id hash before next run or previous blocks will be added to spread sheet worksheets
%block_id = ();
    # End of while read loop
    sleep $config{repeat_delay}

}

__END__


Successful bulkop contains:


MongoDB shell version: 3.2.0
connecting to: test
BLOCKS
BulkWriteResult({
        "writeErrors" : [ ],
        "writeConcernErrors" : [ ],
        "nInserted" : 3,
        "nUpserted" : 0,
        "nMatched" : 0,
        "nModified" : 0,
        "nRemoved" : 0,
        "upserted" : [ ]
})
bye


bulkop with duplicate keys:

MongoDB shell version: 3.2.0
connecting to: test
BLOCKS
2017-01-25T17:36:07.821+0000 E QUERY    [thread1] BulkWriteError: 3 write errors in bulk operation :
BulkWriteError({
        "writeErrors" : [
                {
                        "index" : 0,
                        "code" : 11000,
                        "errmsg" : "E11000 duplicate key error collection: BLOCKS.s1_2blocks index: _id_ dup key: { : \"'30C99_s1_2-20-3024\" }",
etc


Find example:
 db.s1_2blocks.find( { "NUM" : /N0213103/ })

update example:
 db.s1_2blocks.update( { "_id" : "'F6B3_s1_2-20-3011"}, { $set: {"COMMENT" : "updated in db"}} )
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

Not working as expected: db.s1_2blocks.findAndModify( { querey: { "NUM" : /N0213103/}, update: { "COMMENT" : "updated in database!" }, upsert: true})
Check out join overlaps with $lookup, dbrunCommand({"create" : "test"});


When dig fails:
dig: parse of /etc/resolv.conf failed
