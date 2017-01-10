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

# use JSON for encode_json
use JSON;

# use Sys::Hostname;
use feature qw(say switch state);

# use diagnostics;      # Enable for debug
use Data::Dumper;    # Enable for debug

# use Regexp::Debugger; # Enable for debug

our $VERSION = '0.0.17';    # Version number of this script

##  DEFINE FILENAMES FOR CONF AND LOG FILES HERE ##

# File name of conf file (assumed to be in same path as perl script)
my $conf_file = 'ddc.conf';

#### DONT MESS WITH VARIABLES BELOW THIS LINE - these are fixed ####

my $CONF;                   # File handle for conf file
my $EMPTY   = q{};  # Empty string the Critic way
my %config  = ();   # initialise hash to hold config
my @matches = ();   # Array to hold regex patterns used to match candidate files
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

# FAILED DIRECTORY
# Folder used to hold attribute files if these have failed during processing
# error_dir="/home/user/failed/"
error_dir="/home/alice/dbdotcad/failed/"

# LOG DIRECTORY
# Folder used to hold log files
# Must be defined ending in a slash to signify a folder and not a file
# log_dir="/home/user/log/"
log_dir="/var/www/ddclog/"
 

## BEHAVIOURS ##
    
# ATTRIBUTE FILE NAME, PATTERN MATCH CHECK
# Pattern matches required to identify file name for transfer
# Use perl regex format. This is a regex not a glob. Check it works with rxrx.
# e.g to match the numeric part of string '1-123-45-6789-MAD_just a test_file.txt'
# fname_match1="^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*(\.txt|\.TXT)" (N-N-N-A_anYthinG.txt)
# fname_match2="^[0-9]+-([0-9]+-){3}[A-Z]+_.*(\.txt|\.TXT)" (N-N-N-N-A_anYthinG.txt)
fname_match1="^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*(\.txt|\.TXT)"
fname_match2="^[0-9]+-([0-9]+-){3}[A-Z]+_.*(\.txt|\.TXT)"
fname_match3="UNDEFINED"

# DOCUMENT TITLE
# Pattern match for the docuemnt title.  This will be used to validify the document title
# If the file name is used to provide title information, this match filters the title part
# from the whole file name.  This is a bracketed regex intended to return the match in $1
doc_title="(^[0-9]+-[0-9]+-[0-9]+-[0-9])"

# PREFIX FIX (originally added to add missing site code)
# The first match can be corrected to meet fname_match2 on next iteration by adding a prefix
# This is an edge case for legacy drawing numbers with insufficient number groups
# e.g. prefixfix="1-"  Note that it is necessary to add the hyphen if using 
# the fname_match1 example above.  The file will be renamed and meet fname_match2 on the next run
# This is only applied to fname_match1, used to identify the legacy pattern
# Set this to UNDEFINED if not used
prefixfix="1-"

# DB COLLECTION PREFIX
# Collection prefix is intended to be site (and possibly area) code. e.g. 1-20
# Taken from the drawing title with the following match
# Note that collections should not begin with numbers or contain hyphens - ah!
site_match="([1-9][0-9]*-\d+)"

# COLLECTION PREFIX FIX
# If your naming convention begins with a number and contains hyphens, these need to be replace
# to match mongoDB collection naming standards, 1-02 as the start of a collection name
# becomes s1a02 for site 1, area 02
# This is currently a hard coded subsitution s/(\d+)-(\d+)/s$1a$2/xsm

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
        print "\n  ddc.conf would not open for reading \n";
    }
    else {
        print "\n Writing defaut ddc.conf\n";
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
                             #   print "\nSearching $watch_folder at $time\n";

    foreach (@matches) {
        opendir( DIR, $watch_folder )
          || croak "can't opendir $watch_folder - program will terminate";
        my $match = $_;

       #  print "\n matching with > $match\n";
       #  print "\n First match regex is $matches[0]\n";
       # Cannot use $_ within readdir for next match so assigned to a $match var
       # It is possible sort { -M ($watch_folder.$b) <=> -M ($watch_folder.$a) }

        @candidates =
          grep { !/^\./ && -f "$watch_folder/$_" && (/$match/xms) }
          readdir(DIR);

# Prefix fix.  Fix is applied by adding prefix value to legacy file name found in 1st match ONLY
        foreach (@candidates) {

            # print "Candidate file name: $_\n";
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

sub readHANDLEline {
    my ($att_file_name) = @_;

    #  print "\n   Attribute file name = $att_file_name\n";
    my @keys = ();
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
# }

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
                my @keys = readHANDLEline($filewithpath);

                # skip if file is empty or invalid
                next if ( $keys[0] eq 0 | $keys[0] eq 1 );

                # enable for debug
                print "  \n Column headings are:\n";
                foreach my $heading_keys (@keys) {
                    print "  $heading_keys";
                }
                print "\n\n";

# Document TITLE is taken from the filename (or, in later version the TITLE attribute)
# Extract title based on config file regex here:
                my $doctitle = 'doc_title_is_undefined';

        # print "\n File name is $attfile, regex used is $config{doc_title} \n";
                $attfile =~ /$config{doc_title}/xsm;
                $doctitle = $1;
                # site code is the first number(s) before the first - and should not have a leading 0
                # site code is used to prefix the collection name and may become a site-area code in the future
                
                #  $doctitle =~ m/(^[1-9][0-9]*-)/;
               # match doctitle to extract site prefix (from site_match in config file)
                $doctitle =~ /$config{site_match}/xsm; 
               # collection names cannot start with a number or contain a hyphen (without unpredictable delimiting)
               # 1-02 needs to be changed to, say s1a02 for site 1, area 02
               my $collection_prefix = $1;
               # Hardcoded replacement of number-number with snumberanumber
                 $collection_prefix =~ s/(\d+)-(\d+)/s$1a$2/xsm;
                
                # create collection name based on site prefix and collection name for blocks
                my $collection = $collection_prefix.$config{block_collection};
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
# Create primary key by appending the HANDLE to the TITLE.  The + sign is deliberate syntax.  So is leaving in the leading ' provided by AutoKAD
                        my $pkey = "$att[0]+$doctitle";

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
# foreach my $k (sort keys %hof_blocks ) {
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
#  For each key create a line entry in Mongo

                foreach ( keys %hof_blocks ) {

                    # Create json string beginning with mongo _id and document TITLE
                    # Although document TITLE is part of the primary key, db.ATTOUT.find({ "_id": /\+1-02-03-04/ }) is costly
                    # Having a TITLE field allows for future indexing.  TITLE will also exist as an attribute in well made blocks
                    $jstring .= "attout.insert({\"_id\" : \"$_\"";
                    my $column_count = @keys;

                    for ( my $i = 1 ; $i < $column_count ; $i++ ) {

                        # Add key to string bassed on column number
                        # but only if the value is not <> i.e. AutoKAD attout value was empty as this key does not appear in the block
                        # Will throw use of uninitialised value if value of key is empty as is the case
                     #   if (!defined $hof_blocks{$_}[$i]){
                     #   print "\n Row $_, key $keys[$i] had an undefined element $i if last array element is missing \n";
                     #                                    }
                        if ($hof_blocks{$_}[$i] ne '<>') {
                        $jstring .= ", \"$keys[$i]\" : ";

            # Add element value after key based on same column number 
                        $jstring .= "\"$hof_blocks{$_}[$i]\"";
                                                          }
                    }

                    #  Add user name, time and terminating string
                    
                    $jstring .= ", \"_TITLE\" : \"$doctitle\", \"_FILENAME\" : \"$attfile\", \"_ERRANCY\" : \"OK\", \"_USER_TIME\" : \"$config{user_name} $user_time\"})\;\n";

                    # print string on each run to see it build line by line:
                    # print "\n\n$jstring\n\n";
                }
                # Add js command to execute bulk output as last line of js script
                $jstring .= "attout.execute()\;";
                # pring final json bulk op string to screen for debug
                  print "\n\n$jstring\n\n";
                
                # Write js bulk output script to file
                open my $JSON, '>',
                  '/home/alice/dbdotcad/done/mongo_attout.js'
                  or carp "Mongo js file could not be opened\n";
                exit 1 if !print {$JSON} "$jstring";
                close $JSON or carp "Unable to close Mongo js file\n";

                # move file to done directory
                if ( rename $filewithpath, $done_name ) {
                    print "\n $filewithpath moved to:\n $done_name\n";
                }

            }
        }

    }

    # End of while read loop
    sleep $config{repeat_delay}

}

