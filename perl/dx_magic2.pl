#!/usr/bin/perl
use strict;
use warnings;
use Carp;

## dx_magic parser for dxx and dxf format files ##

use POSIX qw( strftime );
use English qw(-no_match_vars);
use File::stat;
use File::Basename;

our $VERSION = '0.0.2';    # version of this script

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

my @folders = ( $dx_watch, $dx_pass, $dx_fail, $dx_attout );

# create folders if they do not exist
foreach (@folders) {
    print "  Finding or creating $_ \n";
    mkdir($_) unless ( -d $_ );
}

# Read watch folder passed as argument to read_dx_atch

sub read_dx_watch {
    my ($watch_folder) = @_;

    #  Define matching regex for dx files here
    my $match = '.*(\.dxf|\.dxx)';

    opendir( DIR, $watch_folder )
      || croak "can't opendir $watch_folder - program will terminate";

    my @candidates =
      grep { !/^\./ && -f "$watch_folder/$_" && (/$match/xsm) } readdir(DIR);

  #    foreach (@candidates) {
  #     print "  Candidate file name: $_ found with grep $watch_folder$match\n";
  #     }
    unless (@candidates) { print "  No candidate files found\n"; }
    return @candidates;
}

# End of read_dx_watch sub

# Read watch folder
my @dx_files = read_dx_watch($dx_watch);

print "  Candidates files for parsing are @dx_files\n";

exit 0;
