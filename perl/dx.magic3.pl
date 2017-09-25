#!/usr/bin/perl
use strict;
use warnings;
use Carp;

## dx_magic parser for dxx and dxf format files ##

use POSIX qw( strftime );
use English qw(-no_match_vars);
use File::stat;
use File::Basename;

our $VERSION = '0.0.3';    # version of this script

##  Custom variables go here:

# dx watch folder [files for parsing]
my $dx_watch = '/home/user1/dx_watch/';

# dx pass folder [processed files]
my $dx_pass = '/home/user1/dx_pass/';

# dx fail folder [files that did not look like a dx file]
my $dx_fail = '/home/user1/dx_fail/';

# dx attout folder [dx files conveted to attout format
my $dx_attout = '/home/user1/dx_attout/';

# Program variables go here:

# CAD version lookup table
my %cadvintage = (
    AC1006 => "R10",
    AC1009 => "R11 and R12",
    AC1012 => "R13",
    AC1014 => "R14",
    AC1015 => "CAD 2000",
    AC1018 => "CAD 2004",
    AC1021 => "CAD 2007",
    AC1024 => "CAD 2010",
    AC1027 => "CAD 2013",
    AC1032 => "CAD 2018",
);

my @folders = ( $dx_watch, $dx_pass, $dx_fail, $dx_attout );

# Print welcome message & check folders exist

print "***  X File Magic $0 version $VERSION  ***\n";

# create folders if they do not exist
foreach (@folders) {
    print "  Checking $_ exists";
#    mkdir($_) unless ( -d $_ );
     if (! -d) { print " - not found, so creating ...\n"; mkdir; }
    else { print " - OK\n"; }
}

# Sub to read watch folder passed as argument to read_dx_atch

sub read_dx_watch {
    my ($watch_folder) = @_;

    #  Define matching regex for dx files here
    my $match = '.*(\.dxf|\.dxx)';

    opendir( DIR, $watch_folder )
      || croak "can't opendir $watch_folder - program will terminate";

    my @candidates =
      grep { !/^\./xms && -f "$watch_folder/$_" && (/$match/xsm) } readdir(DIR);

    # Concat path.filename with map
    my @candidates_withpath = map { $watch_folder . $_ } @candidates;

    # foreach (@candidates) {
    #  print "  Candidate file name:>$_< found with grep $watch_folder$match\n";
    #  }
    if (! @candidates) { print "  No candidate files found\n"; }
    return @candidates_withpath;
}

# End of read_dx_watch sub

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
            print "$seekname cannot be read\n";
            return 1;
        }
        else {

            seek $HANDLE, -$bytes, 2
              ; # number of bytes needs to be negative -$bytes as seek counts from the end if next argument is 2
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
        print "$seekname not found\n ";
        return 2;
    }

}


## The Program ##

# Read watch folder
my @dx_files = read_dx_watch($dx_watch);
# print "  Candidates files for parsing are @dx_files\n";

# process candidate files

foreach (@dx_files) {
    print "  Checking $_ is static ...";
    my $stat1 = statnseek($_);
    sleep 1;
    my $stat2 = statnseek($_);
    if ( $stat1 eq $stat2 ) {
        print "  passed.\n";
    }
}

exit 0;
