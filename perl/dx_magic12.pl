#!/usr/bin/perl
use strict;
use warnings;
use Carp;

## dx_magic parser for dxx and dxf format files ##

use POSIX qw( strftime );
use English qw(-no_match_vars);
use File::stat;
use File::Basename;
use File::Copy;
use File::Path 'rmtree';    # Exported by default
use Data::Dumper;
use Excel::Writer::XLSX;

our $VERSION = '0.0.12';    # version of this script

##  Custom variables go here:

# dx watch folder [files for parsing]
my $dx_watch = '/home/user1/dx_watch/';

# dx pass folder [processed files]
my $dx_pass = '/home/user1/dx_pass/';

# dx fail folder [files that did not look like a dx file]
my $dx_fail = '/home/user1/dx_fail/';

# dx attout folder [dx files conveted to attout format
my $dx_attout = '/home/user1/dx_attout/';

# dx merge folder [dxf file for metadata replacement ]
my $dx_merge = '/home/user1/dx_merge/';

# dx Excel folder [Excel, .xlxs format version of the attout file]
my $dx_xlsx = '/home/user1/dx_xlsx/';

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

# print Dumper (\%cadvintage);

my @folders = ( $dx_watch, $dx_pass, $dx_fail, $dx_attout, $dx_merge, $dx_xlsx );

# atto variable will hold the output attout file name also sued to create an excel version

our $atto; 

# Print welcome message & check folders exist

print "\n ***  X File Magic $PROGRAM_NAME version $VERSION  ***\n";

# create folders if they do not exist & add readme
foreach (@folders) {
    print "  Checking $_ exists";

    #    mkdir($_) unless ( -d $_ );
    if ( !-d ) { print " - not found, so creating ...\n"; mkdir; }
    else       { print " - OK\n"; }

    # Add readme to watch folder
    my $readme = $dx_watch . 'readme.txt';
    if ( !open my $README, '>', $readme ) {
        print "\n  failed to open $readme\n";
    }
    else {
        print $README
"   ## dx_magic watch folder ##\n\n   Valid dxx & dxf files found in here will be processed to create attout.txt metadata files\n   in $dx_attout, with the same file name & a new .txt extension\n   The original file is then moved to $dx_pass or $dx_fail folder as appropriate\n";
    }
}    # End of creating folders sub

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
    if ( !@candidates ) { print "  No candidate files found\n"; }
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

}    # End of statnseek

# xparser sub routine, take filename with path as argurment, return ref to hash of blocks (hashes)

# Takes approved candidate filename + path as argument  where a comma is a new line

# AcDbSequenceEnd & SEQEND codes may be optional and not used by prog

# ignoring 0 & 100 code and in this order of precedence
# HANDLE: (DOUBLE SPACE) 0, INSERT, (DOUBLE SPACE) 5, <HANDLE ENTITY H_xxxx>,
# BLOCKNAME: 100, AcDbBlockReference, (DOUBLE SPACE) 2, <BLOCKNAME> ,

# Beware AcDbAttribute comes before the 1, VALUE in a AUTO dxx and before the 2, TAG KEY in a PROG:
# AUTO DXX TAGS: 100, AcDbAttribute, (DOUBLE SPACE) 1,<TAG VALUE>,  (DOUBLE SPACE) 2, <TAG KEY>,
# PROG DXX & AUTO DXF TAGS: (DOUBLE SPACE) 1,<TAG VALUE>,  100, AcDbAttribute, (DOUBLE SPACE) 2, <TAG KEY>,
# So for both  using ATTRIB, (DOUBLE SPACE) 5, (DOUBLE SPACE) 1,<TAG VALUE>, (DOUBLE SPACE) 2, <TAG KEY>, instead of using AcDBAttribute	
# ATTRIB, (DS)5, is followed by an incremented handel in dxx and an incremented handel then 330,<INSERT_HANDEL> in dxf, 330 is a pointer to the owner object

# TODOs #  process BLOCK (DS)5, AcDbBlockBegin or set state higher for AcDbBlockBegin and others ...
# set state to something higher (try BLOCKNAME) for AcDblockBegin, AcDbBlockTableRecord, AcDbDimStyleTableRecord, AcDbSymbolTableRecord preceed (DS)2
# use ATTRIB, (DS)5, instead of AcDbAttribute & allow for TAG before VALUE by having a $state VALUE OR $state TAG condition
# Capture Document $TITLE, (DS)1, <Drawing Tilte>
# Capture layout (viewport) tabs LAYOUT, (DS)5, AcDbLayout, (DS)1, <Layout Tag name>

# Only capturing one value, key pair so far ... use $ state to specifiy the actual match variable next required.

# Also looking for the dxf version (not present in a dxx)
# VERSION:  (DOUBLE SPACE) 9, $ACADVER, <VERSION CODE>,

# THINGS TO IGNORE:
# AcDb* (anything other than AcDbBlockReference), (DS) 2 may be problematic
# AcDbBlockBegin, (DS) 2,  DONT TAKE THIS VALUE
# BLOCK_RECORD, (DS), (DS) 5, This is followed by group codes for graphical block entities that can be ingnored, earler in file along with AcDbBlockTableRecord
# AcDbField is a default constructor in dxf with ..1 ..2 coded content that is not attribute releated,
# set state to FIELD to prevent further processing until next INSERT
# AcDbBlockBegin, (DOUBLE SPACE), 2, can be blockname or *Model_Space or *Paper_Space, then there is a (DS) 1 before the next INSERT, so dont start INSERT before -- wait for INSERT ... do this first
# AcDbBlockTableRecord, (DOUBLE SPACE) 2,
# AcDbDimStyleTableRecord, (DOUBLE SPACE) 2,
# AcDbSymbolTableRecord, (DOUBLE SPACE) 2,

sub xparser {
    my ($xfile) = @_;
    my %hof_blocks;

# dx metadata coverted to hash of block hashes, these are the droids we are after
# Desired result of each file parsed, a handle with hash of: key (tag name), (attribute tag) value pairs.
# Looks like this: $hof_blocks{"$handle"}{TAGNAME} = ATTRIBUTE_VALUE;

    our @tags = qw(HANDLE BLOCKNAME);

    # Array of tag key names in order of discovery (i.e CAD order)
    # To match attout format and begin with HANDLE & BLOCKNAME

    our %tagcheck;

# Hash to keep track of unique tag names to create an in order array @tags (after HANDLE & BLOCKNAME)

    print "  Going to parse $xfile\n";

# sub to add new tag if its not been seen before.  Array order preserves original attribute order
# original order is not needed but makes debugging from CAD so much easier
    sub addnewtag {
        my ($newtag) = @_;
        if ( exists $tagcheck{$newtag} ) { return; }
        else { $tagcheck{$newtag} = 1; push @tags, $newtag }
    }

    # End of addnewtag sub

    my $handle;       # Handle entity found when sequence 0INSERT5 found
    my $blockname;    # Holds Blockname once identified
    my $tagvalue;     # Holds tag value onece identified
    my $tagkey;       # Holds tag (key) name
    my $version = 'DXX of unknown version';
    my $state   = 'X'
      ; # State is X unless sequence in progress, H_xxxx if handle found, then current process state
    my $attrib5_count =
      0;    # Using ATTRIB,(DS)5 instead of AcDbAttribute fields.  ATTRIB conistently comes before AcDBAttribute in dxx & dxf, so far ....
    my $seqend_count  = 0;    # count for SEQEND
    my $acdbend_count = 0;    # count for AcDbSequenceEnd

    open( my $X_FILE, '<', $xfile ) or die "$xfile would not open";
    while (<$X_FILE>) {
        my $line = $_;

        for ($line) {

            # Check for $ACADVER, if this is present its a DXF, not a DXX
            if    ( $line =~ /\$ACADVER/ ) { $state = 'ACADVER'; }
            elsif ( $state eq 'ACADVER' )  { $state = 'ACADVER1'; }
            elsif ( $state eq 'ACADVER1' ) {
                $state = 'DXF';
                $line =~ s/\r?\n$//;
                $version = "$line";
            }

            # print " Current line is $line";
            # Look for group 5 INSERT and then extract attribute metadata
            if ( $line =~ /^INSERT\r?\n/ ) { $state = 'INSERT'; }
            elsif ( $state eq 'INSERT' && $line =~ /^[ ]{2}5\r?\n/ ) {
                $state = 'INSERT5';
            }

            # look for use of sequence end codes
            elsif ( $line =~ /^SEQEND/ )          { $seqend_count++; }
            elsif ( $line =~ /^AcDbSequenceEnd/ ) { $acdbend_count++; }

            elsif ( $state eq 'INSERT5' ) {
                $line =~ s/\r?\n$//;
                $handle = $line;
                $state  = "H_$handle" . '_';

                # _HANDLE_ underscors make the handle easier to read and parse
            }
            elsif ( $state =~ /^H_.*_/ && $line =~ /^AcDbBlockReference/ ) {
                $state = $state . 'AcDbBlock';
            }
            elsif ( $state =~ /^H_.*AcDbBlock/ && $line =~ /^[ ]{2}2\r?\n/ ) {
                $state = $state . '2';
            }
            elsif ( $state =~ /^H_.*AcDbBlock2/ ) {
                $line =~ s/\r?\n$//;
                $blockname = $line;
                $state     = 'BLOCKNAME';

                # Add blockname to hof_blocks but after ATTRIB,  5 may be better ...
               # $hof_blocks{"$handle"}{"BLOCKNAME"} = "$blockname";

#  print " BLOCKNAME: blockname for $handle is $blockname, state is $state, line is $line\n";
            }
            
#  BLOCK_RECORD field appears in dxf files at the start, this is just to check the stage = DXF at this point
#            elsif ( $line =~ /^BLOCK_RECORD/ ) {
#                    print "  BLOCK_RECORD found while state = $state\n"; 
#                  }




           elsif ( $state eq 'BLOCKNAME' && $line =~ /^ATTRIB/ ) {
                 $state = 'ATTRIB';
                 }
           
#  Here we could change to switch satements to look for either Value or Tag Name, which ever comes first.  if 1 or if 2.
           elsif ( $state eq 'ATTRIB' && $line =~ /^[ ]{2}5\r?\n/ ) {
                  $state = 'ATTRIB5';
                  $attrib5_count ++;
                  # print "ATTRIB5: blockname for $handle is $blockname, state is $state, line is $line\n";
                  # Add blockname to hof_blocks but only after an ATTRIB, (DS)5, as other AcDbBlockReferences, not Attribute related may occur
                  $hof_blocks{"$handle"}{"BLOCKNAME"} = "$blockname";

                  }



            elsif ( $state eq 'ATTRIB5' && $line =~ /^[ ]{2}1\r?\n/ ) {
                $state = 'VALUE';
            }
            elsif ( $state eq 'VALUE' ) {
                $state = 'TAGVALUE';
                $line =~ s/\r?\n$//;
                $tagvalue = $line;

# print " TAGVALUE: blockname for $handle is $blockname, state is $state, line is $line\n"
            }


# TODO TEST AGAIN with dxf may need setting back to BLOCKNAME not ATTRIBUTE
# Once looking for attributes there may be AcDbFields if next line is (DS) 1, which need to be ignored
# until next INSERT sequence, so setting state to FIELD if AcDBField found
#  elsif ( $state eq 'ATTRIBUTE' && $line =~ /^AcDbField/ ) {
#    $state = 'FIELD';
#  }

            elsif ( $state eq 'TAGVALUE' && $line =~ /^[ ]{2}2\r?\n/ )
            {
                $state = 'TAG';
            }
            elsif ( $state eq 'TAG' ) {

# Keep looking for more attributes by setting state to BLOCKNAME to search for next value (value preceeds tag/key)
                $state = 'BLOCKNAME';
                $line =~ s/\r?\n$//;
                $tagkey = $line;

                # Write key/value pairs to hash of block handles
                $hof_blocks{"$handle"}{"$tagkey"} = "$tagvalue";

           # print "Handle is $handle, Key is >$line<, Value is >$tagvalue< \n";

                addnewtag($line);
            }

        }

    }    # End of while X_FILE

    # At end of file parsing, print name and version if found
    if ( exists( $cadvintage{$version} ) ) {
        print
"\n Finished parsing $xfile\n (DXF file from $cadvintage{$version})\n";
    }
    else {
        print
"\n Finished parsing $xfile \n (DXX file or DXF of unknown version)\n";
    }

    # move parsed file to passed directory

    my $passed = $dx_pass . basename($xfile);
    print " Moving to $dx_pass ... \n\n";
    move( $xfile, $passed ) or croak "move of $xfile failed";

    print
"\n ATTRIB,  5 count: $attrib5_count \n SEQEND count: $seqend_count, AcDbSequenceEnd count: $acdbend_count\n";

# Clear tagcheck & orphan, seqend, acdbsequenceend counts before next run of xparser
    %tagcheck            = ();
    $attrib5_count = 0;
    $seqend_count        = 0;    # count for SEQEND
    $acdbend_count       = 0;    # count for AcDbSequenceEnd

# Retrun pointer to hash of block hashes, and array of tag (key) names in CAD order of discovery
    return ( \%hof_blocks, \@tags );
}    # End of xparser

## Sub to create Excel version of attout file

# Take attout filename with and excel file path as arguments
sub excelout {

# Limit columns to  52 as a spread sheet bigger than that is going to be painful
# This becomes A to AZ, created range in an @alph

my @alph = ( 'A' .. 'Z', 'AA' .. 'AZ' );


    # $row is the first row number for attribute data
    my $row = '5';
    my ( $attout, $excelpath ) = @_;
    my $attout_basename = basename($attout);
    # substitute xlsx extension
    my $excel = $attout_basename;
    $excel =~ s/\.txt/\.xlsx/;

    my $excel_withpath = $excelpath.$excel;

    print "  Reading attout_basename $attout_basename and creating $excel_withpath\n";

    my $workbook = Excel::Writer::XLSX->new("$excel_withpath");

    $workbook->set_properties(
        title  => "Attribute data from $attout_basename",
        author => 'DeeV',
        comments =>
'Support cross platform Open Source solutions.  Respect CC & GPL Licenses',
    );    # This might not be visible from Open Office

    my $worksheet_rm = $workbook->add_worksheet('Readme');
    $worksheet_rm->write( 'B2', "Created by dx_magic reader $VERSION" )
      ;    #  worksheet created for info, notices & copyright
    $worksheet_rm->write( 'B3',
"This software is free but copyright (c) 2017 by Floss (floss1138\@gmail.com) - a dolphin friendly PDP project.  All rights reserved. XLSX by John McNamara."
    );
$worksheet_rm->write( 'B4',
"You are free to use, copy and distribute this software under the same GPL terms as the Perl 5 programming language."
    );
    $worksheet_rm->write( 'B6',
'Hopefully you have a strict block naming policy which enforces use of a version number, prohibits strange characters and limits the the block name to 31 characters?'
    );
$worksheet_rm->write( 'B7',
'As there are name restictions in Excel that do not apply to CAD block data; plan block data to migrate easily into spread sheets.'
    );

   $worksheet_rm->write( 'B7',
'Your blocks include the document title from the document title properties field?  Dont think about putting this in a database without referencing the originating document.'
   );

 my $worksheet_attout = $workbook->add_worksheet('attout');
      #  create attout data worksheet with formatting


my $format =
              $workbook->add_format( bold => 1, bg_color => 'yellow' );

            # Format head line, set_row starts from 0
            $worksheet_attout->set_row( 3, undef, $format );

# open attout here and read into attout worksheet


return 0;
}




### The Program ###

# loop forever with a 1 second pause between runs
while ( sleep 1 ) {

    # Read watch folder, looking for correctly named files
    my @dx_files = read_dx_watch($dx_watch);

    # print "  Candidates files for parsing are @dx_files\n";

    # check candidate files are static and have expected header

    foreach (@dx_files) {
        my $dx = $_;
        print "  Checking $dx is static ...";
        my $stat1 = statnseek($dx);
        sleep 1;
        my $stat2 = statnseek($dx);

        # If file is static stat check will be the same string
        if ( $stat1 eq $stat2 ) {
            print "  OK\n";

            # If static, open file and check 1st line is acceptabale format
            if ( !open my $XFILE, '<', $dx ) {
                print "\n  failed to open $dx\n";
            }
            else {
                my $line = <$XFILE>;

# Test files created in Linux have \n, Windows needs \r\n, just matching to end $ also depends on newline, hence \r?\n
                if ( $line =~ /^[ ]{2}0\r?\n/ ) {
                    print "  $_ header looks OK, lets dig deeper\n";
                    close $XFILE or carp "Unable to close $dx file";

              # parse file $dx, return refs to hash of blocks and tagnames array
                    my ( $hofblocksref, $tagnameref ) = xparser($dx);

                    # deref the retuned address for hash of blocks and tag names
                    my %hofblocks = %$hofblocksref;
                    my @tagnames  = @$tagnameref;

                    # print Dumper (\%hofblocks);
                    print " Tag names: @tagnames\n";

                    #  attout file name with path will be $atto
                    $atto = $dx_attout . basename($dx);
                    $atto =~ s/\.dx.$/\.txt/;

                    print "  Looking for existing attout file, \n  $atto\n";
                    if ( -e "$atto" ) {
                        print
"  Old $atto already exists, \n  ... so its going to be deleted!\n";

                        unlink $atto or warn "  Could not delete $atto";
                    }
                    attout( $atto, \@tagnames );
                    foreach my $HANDLE ( sort keys %hofblocks ) {

                        # DEBUG foreach print " HANDLE: $HANDLE ";

                 # Add handle to values array as first element and add leading '
                 # leading ' is used in attout formatted file
                        my $qhandle = "'" . $HANDLE;
                        my @values  = ($qhandle);

                        # The tag values are known so use for each tag here
                        #  foreach my $TAG ( keys %{ $hofblocks{$HANDLE} } ) {
                        #   push @values, $hofblocks{$HANDLE}{$TAG};
                        #     print " $TAG: $hofblocks{$HANDLE}{$TAG} ";
                        # }
                        # write next line of handle, value, value ...
                        foreach (@tagnames) {
                            my $Tag = $_;
                            next if $_ =~ /^HANDLE$/;
                            if ( defined( $hofblocks{$HANDLE}{$Tag} ) ) {
                                push @values, $hofblocks{$HANDLE}{$Tag};

                    # DEBUG for each   print "$Tag: $hofblocks{$HANDLE}{$Tag} ";
                            }
                            else { push @values, '<>'; }
                        }    # end of foreach tagnames

                 # attout writes current line to attout.txt,
                 # takes attout filename and ref to array of values as arguments
                        attout( $atto, \@values );

                        # DEBUG foreach  print "\n";
                    }    # end of for each HANDLE
                }    # end of if $line header looks OK
                else {
                    print
"  $_ has the wrong header for a dx file, moving to $dx_fail\n";
                    close $XFILE or carp "Unable to close $_ file";

                    # Move bad dx file to fail directory
                    # Take filename and change the path to the fail directory
                    my $failed = $dx_fail . basename($_);
                    move( $_, $failed ) or croak "move of $_ failed";
                }

            }    # end of <$XFILE> processing

        }    # if static

        print "  Excel version of $atto about to be created ...\n";
        excelout ($atto, $dx_xlsx);

    }    # end of foreach dx_file

    print
" \nEnd of processing, lets check the watchfolders again...\n";




}    # end of while (sleep 1)

# attout sub takes 'attout filename with path' and 'array of elements reference'
# as the next line to write  (append)
# the attout file shuould have the same name as the dx but with a txt extensions
sub attout {
    my @attout_elements    = @_;
    my $attout_nameandpath = $attout_elements[0];
    my $elements           = $attout_elements[1];

#  print "\n Attout filename will be, $attout_nameandpath,\n tags values are @$elements\n";
    open( my $ATTOUT, '>>', $attout_nameandpath )
      or die "$attout_nameandpath would not open";

    # elements need to be tab deliminated
    print $ATTOUT join( "\t", @$elements ), "\r\n";
    close($ATTOUT) or carp "Cannot close $attout_nameandpath\n";

}    # End of attout sub
exit 0;

__END__


