#! /usr/bin/perl
use strict;
use warnings; 
no warnings "unopened"; # prevents warning "tell() on unopened filehandle xxx" as filehandle should be closed, i.e. unopened 
no warnings "uninitialized"; # prevents uninitialized warnings for blank cells in xlsx
use POSIX; # required for timestamp using strftime
use Excel::Writer::XLSX; # required for xlsx creation sub routine 
use Spreadsheet::Read; # required for xlsx read subroutine


# create file name list found in $attodir and find valid candidates, then move & datestamp file to valid cnadidate directory
# call subroutine writexlsx() to convert valid candidate attout .txt file to .xlsx
# call subroutine readxlsx() to convert valid candidate .xlsx to  attin .txt


# Mandatory variables.  These must be created/defined for your system - note change of attout <> attout_to_xlsx name
# my $attodir = "/home/dog/Documents/Perl/progs/readdir/attout_to_xlsx"; # inbound drop box directory for attout files - THIS MUST EXIST
# my $vcdir = "/home/dog/Documents/Perl/progs/readdir/attvalid"; # valid candidate directory for attout_valid.txt files - THIS MUST EXIST
# my $xlodir = "/home/dog/Documents/Perl/progs/readdir/attout"; # xlsx converted version of attout_valid.txt - THIS MUST EXIST
# my $xlidir = "/home/dog/Documents/Perl/progs/readdir/xlsx_to_attin"; # xlsx to be converted to attin.txt - THIS MUST EXIST
# my $attidir = "/home/dog/Documents/Perl/progs/readdir/attin"; # outbound catch box for attin files - THIS MUST EXIST


# Mandatory variables.  These must be created/defined for the pi
my $attodir = "/home/cadbox/attout_to_xlsx"; # inbound drop box directory for attout files - THIS MUST EXIST
my $vcdir = "/home/cadbox/attvalid"; # valid candidate directory for attout_valid.txt files - THIS MUST EXIST
my $xlodir = "/home/cadbox/xlsx"; # xlsx converted version of attout_valid.txt - THIS MUST EXIST
my $xlidir = "/home/cadbox/xlsx_to_attin"; # xlsx to be converted to attin.txt - THIS MUST EXIST
my $attidir = "/home/cadbox/attin"; # outbound catch box for attin files - THIS MUST EXIST


# Optional variable.  You are free to alter this
my $flimit = 128; # filename character lenght limit including extension

# Dont mess with anything below this line unless you feel like debugging it
my @dirlistatto = (); # array to store directory list of attout files
my @dirlistxlsxin = (); # array to store directory list of xlsx_in files
our $newname = "att_valid.txt"; # Global variable containing the moved attout file name & path ready for turing into xlsx 
our $newxlsx = "att_valid.xlsx"; # Global variable containing moved valid xlsx_in file name & path ready for turing into attin text
our $xlsxout = "att_toxlsx.xlsx"; # Global variable containing the filename & path used for the xlsx, will be changed to newname.xlsx

### WRITE XLSX ####

sub writexlsx() #Write attout data to xlsx spreadsheet
{
# Declare variables here:
my $version = "V0.03"; # Version of this subroutine 
my $row=3; # Starting row number used to populate spread sheet to allow for a heading if necessary
my $custom_block = 0; # If matching custom block found in attributes then set this flag
my $timestamp = strftime( '%d/%m/%Y %H:%M:%S', localtime ); 
my @alph= ("A".."Z"); # The Range Operator (..) is shorthand to set up arrays, here the upper case alphabet
my @alph_ext= ("AA".."AI"); # Extending the cell range for 35 columns requires AA AB etc.
push (@alph, @alph_ext); # Add alph_ext to alph giving a total range that goes A B...X Y Z AA...AI (Artificial Intelligence)
our $cell="A1"; # Cell position held in global variable, made global for potential sub routine call
our %cell_att = (); # Initialize an empty hash, that will contain the key=cell A1 B1 etc. value=attribute from attout


# Chomp removes the current "input record separator" Linux is \n (LF ^J); Windows preceed this with \r (CR ^M). Built-in perl variable $/ may need to be defined for both CR LF as the attout file was derived on Windows
# $/ = "\r\n"; # Define input record separator used by attout.txt derived from Windows - Linux works with or without this but without the last cell value will include x000D
# I thought this was necessary for a Windows file run on Linux but works OK between Linux and Strawberry without any modification, but...
# If you define the record separator for Windows and run this on Strawberry then the while <ATTOUT> loop does not see the end of line
# print "\nNew Name is: $newname \n";
open my $ATTOUT, "$newname" or die "Cannot find valid attout.txt file:  $!";
# open my $ATTOUT, "attout.txt" or die "Cannot find file:  $!"; # open for read	
while (<$ATTOUT>) 
	{ 
	$_ =~ s/\r?\n$//; # Substitute return r?, match to end of string, with nothing - an alternative to pre defining $/ for Windows - works on both Linux and Strawberry?
	# Split line tab into an array taking $_ and placing it in @att
	my @att = split(/\t/,$_); # \s+ is usual for any white spaceS, or split(' ',$_) would also take a tab and any white space but data contains spaces so use \t for tab
	chomp(@att); # Remove new line (defined above for Windows CR LF) from array data
	#First Element is $att[0], Second Element is $att[1] etc.
	my $element_count=0; # Count used to access array.  Using strict my $variables requires this to be declared before the for loop
	
		foreach my $val (@att) {
		# print "> ${val} "; # Each data element in attout
		if (${val} =~ m/001_equ_mdu/){
			$custom_block=1;} # set custom to 1 if 001_equ_mdu found
		$cell="$alph[$element_count]$row"; # Each intended cell value for spread sheet into global variable our $cell - *** use of uninitiated value if more cells present used in spread sheet ***
		# print "Cell is: $cell<\n";
		$cell_att{$cell}=${val}; #  Populate the hash %cell_att
				
		$element_count++;
					}

$row++; # increment row number for each pass of attout file
	
	}

# Sanity checking print routine
#$, = " "; # Set output field operator to space to make things easeir to read
#print %cell_att  ; # Sanity check that hash has been populated.  This wont be in order of course
#print "\n\n";
# print keys(%cell_att); # Print out the keys only.  This wont be in order either and its a garble of addresses 
print "Data found at A3 through D3 is: \n";
my @slice =@cell_att{"A3","B3","C3","D3"}; #Take a slice out of the hash.  If data starts at row 3 then values are the column headers
print join ("\n", @slice);
if (exists $cell_att{A3}){print "\nA3 exists.  Lets rock\n";}
#Scalar value @cell_att{"A3"} better written as $cell_att{"A3"} at xlsx4.pl line 50 was my $A3data=@cell_att{"A3"}
my $A3data=$cell_att{"A3"};# print "\nLooking in directory $attodir for a valid file e.g. attxxxxx.txt\n\n";
# opendir(DIR, $attodir) || die "can't opendir $attodir: $!";

my $A4data=$cell_att{"A4"};

print "Data at A3 is $A3data, Data at A4 is $A4data\n\n";

# Sort by key and print associated value
#foreach my $key ( sort keys %cell_att )
#{
 # print "key: " . $key . " value: " . $cell_att{$key} . "\n";
#}

my $xlsxout = $newname; # Set xlsxout to be the same as newname.txt
# create name for xlsx out file; substitute valid candidate dir with xl out dir and replace .txt with .xlsx 
$xlsxout =~ s/\.txt$/\.xlsx/;
$xlsxout =~ s/$vcdir/$xlodir/;
print "\nxlsx file will be called $xlsxout \n";                              

        my $workbook = Excel::Writer::XLSX->new( "$xlsxout" );  

$workbook->set_properties(
        title    => 'attout data',
        author   => 'DeeV',
        comments => 'Support cross platform Open Source solutions.  Respect CC & GPL Licenses',
    			);  # This might not be visible from Open Office

        my $worksheet1 = $workbook->add_worksheet('Attributes');	# Will be sheet 1 if not specified
	my $worksheet2 = $workbook->add_worksheet('Custom_1');		# Worksheet 3 is a custom verson of 1      
	my $worksheet3 = $workbook->add_worksheet('Readme');		# Worksheet 3 is a readme
	
        #$worksheet1->write( 'A3', $A3data );                   
        #$worksheet1->write( 'C2', 'Column 2' ); 
        #$worksheet1->write( 'D2', 'Column 3' );

# Write the hash data into the cells
foreach my $key ( keys %cell_att )
{
 $worksheet1->write( $key, $cell_att{$key} );
 $worksheet2->write( $key, $cell_att{$key} );
# print "key: " . $key . " value: " . $cell_att{$key} . "\n"; # Debug print statement to send output to terminal
}

# Format Worksheet 1:
# Set the column format.  Cells definitions cannot overlap or last set_column is active
# set_column syntax: set_column( $first_col, $last_col, $width, $format, $hidden, $level, $collapsed )
$worksheet1->set_column('B:AI', 12);				# Columns B-AI width for default font at 11pt.  AutoFit is only available at run time.
$worksheet1->set_column( 'A:A' , undef , undef,  1, 0, 0 ); 	# This hides column A to A, the first attout HANDLE column 
# Format row (1st row is zero)
my $format1 = $workbook->add_format( bold => 1, bg_color => 'yellow' ); # color => is the font color
$worksheet1->set_row( 2, undef, $format1 );

# Apply custom formating if custom block detected, otherwise it will display all in default cells
if ($custom_block eq 1){
  #Format for Worksheet 2:
  $worksheet2->set_column('B:AI', 16);				# Columns WIDTH
  $worksheet2->set_column( 'A:B' , undef , undef,  1, 0, 0 ); 	# This hides column A to B
  $worksheet2->set_column( 'D:D' , undef , undef,  1, 0, 0 ); 	
  $worksheet2->set_column( 'I:O' , undef , undef,  1, 0, 0 ); 	
  $worksheet2->set_column( 'Q:U' , undef , undef,  1, 0, 0 ); 	
  $worksheet2->set_column( 'X:X' , undef , undef,  1, 0, 0 ); 
  $worksheet2->set_column( 'AC:AC' , undef , undef,  1, 0, 0 ); 	# Some of these dont work consistently  

  my $format2 = $workbook->add_format( bold => 1, bg_color => 'yellow' ); # color => is the font color
  $worksheet2->set_row( 2, undef, $format1 );
  } 

#Format Worksheet 3:
$worksheet3->write( 'B2', "Created by Attout Reader $version run at $timestamp");     # Second worksheet created for info, notices & copyright
$worksheet3->write( 'B3', "This software is Free - copyright (c) 2012 by Floss (floss1138\@gmail.com) as part of a personal Rpi project.  All rights reserved.");  
$worksheet3->write( 'B4', "You are free to use, copy and distribute this software under the same GPL terms as the Perl 5 programming language."); 
$worksheet3->write( 'B5', "The Excel module used is copyright (c) John McNamara under GPL http://opensource.org/licenses/gpl-license.php");  
$worksheet3->write( 'B8', 'Notes:');    
$worksheet3->write( 'B9', 'The Attribute sheet first (A = HANDLE) column is intentionally hidden by default');  
	if ($custom_block eq 1){
	$worksheet3->write( 'B10', 'One or more specific NSBs were found - custom formatting was applied'); 
	}
} # End of WRITE XLSX sub routine

#### READ XLSX #### based on /xlsx/stpreadsheetread6.pl

sub readxlsx # read xlsx and create an attin.txt file
{
print "\nreadxlsx sub has been called, will use new name $newxlsx\n";
local $/ = "\r\n"; # new line defined for windows, might need to be local to read sub?
my $xlsx = ReadData ("$newxlsx");
print "First sheet cell A3 is:\n";
print $xlsx->[1]{A3}; #Prints sheet 1, cell A1 usually HANDLE as a ceck but we start at A3. Will warn if cell blank: Use of uninitialized value in print at filename.pl
my @row = Spreadsheet::Read::row($xlsx->[1],4); # This returns [sheet], Row - all of it but if there are blanks it is an uninitialized value
my $attin_ext = ".txt"; # File extension for attin files - these will usually be .txt dos files

my $attin_file = $newxlsx . $attin_ext; # Concatenate file name 
$attin_file =~ s/\.xlsx//; # Remove previous extension
$attin_file =~ s/$vcdir/$attidir/; # Substitute valid candidate directory with attin directory where file is to be written
print "\nattin file will be called $attin_file\n";
open my $FILEOUT, ">", "$attin_file" or die "Cannot open output file $!";  # with append access does not overwrite original.  foreach is OK if file remains open i.e. adds to existing content
local $" = "\t"; # set the output field separator to a tab
my $blankcount=0;
for (my $rowcount=1; $blankcount<3; $rowcount++)
	{
		
	my @row = Spreadsheet::Read::row($xlsx->[1],$rowcount); # read each row into an array
	my $row = @row; # number of elements in the array.  If its zero then the line is empty, but blank fields/tabs/whitespace count so need to check for uninitialized values

	# Will bail out of the for loop if blank count exceeded i.e. if $blancount < 3 will stop after 3 (totally - no white space not tabs) blank lines	
	if ($row == 0)	{
			$blankcount++; # print "blankcount is $blankcount\n";
			} 
	if ($row > 1)
		{
		# print "row is $row >> @row\n"; This would print out here if there were empty values in a whole line
		my $firstelement = $row[0]; # check first element in array - if its HANDLE or '[any_uppercase_or_numbers x 4] then its a handle value, @row[0] better written $row[0]
			if ($firstelement =~ /^HANDLE|^\'[A-Z0-9]{4}/)
			{
			# print "Row array contains: @row\n"; # send this to a file and you have attout, this prints to screen for debug
				
			print $FILEOUT "@row$/"; # The new line needs to be MS complient hence the $/ defined as \r\n 
			} # close if ($firstelement...
		} # close if ($row > 1...
	} # close for (my $rowcount...
print "attin file created\n";
close($FILEOUT);

} # close sub readxlsd


# Run loop to read directory for attout and xlsx_to_attin files

while (1) #loop foerever
{
#### LOOK FOR VALID ATTOUT FILES APPEARING IN ATTOUT DIR #####
# print "\nLooking in directory $attodir for a valid file e.g. attxxxxx.txt\n\n";
opendir(DIRATTOUT, $attodir) || die "can't opendir $attodir: $!";

@dirlistatto = grep {(!/^\.\.?$/) && -f "$attodir/$_" && (/.txt$/) && (/^att/)} readdir(DIRATTOUT);
# grep !/^\.\.?$/, readdir(DIR); removes . .. ... but then sub directory names will be present
# grep -f searches the file name returned by readdir, if its not a file it will be empty and matches nothing
# Must end in .txt or begin att, use /.txt$/i for case insensitive match

foreach my $fname (@dirlistatto) 
	{
	# print "Found file with correct pre & postfix >  ${fname} \n"; # Each valid data element in attout
	my $namelen = length ${fname}; # filename lenght including extension
		if ($namelen > $flimit)	{next} # skip if filename exceeds $flimit charaters
	# print "file name length is $namelen \n";
	my $fullname = "$attodir/${fname}";
	my $filesize1 = -s $fullname; # -s is a perl file operator that returns the file size in bytes
		if ($filesize1 < 10 || $filesize1 > 1000000){next} # if less than 10 bytes or larger than 1M it can be skipped
	select(undef, undef, undef, 0.5); # wait half a second then check file size again
	my $filesize2 = -s $fullname; 
		if ($filesize1!=$filesize2) {next} # skip if file size is NOT the same after delay
	#Optional check to see if file has been closed	- file handle should be unopend and tell will warn without no warnings exclusion	
		if(tell(${fname}) != -1) {print "\n $fullname is open - skipping this file until its closed\n";
					next;
					}
					
	$newname = "$vcdir/${fname}"; # Define new name based on existing name but in the valid candidate directory
	my $timestamp = strftime( '_%d%m%Y_%H%M%S', localtime ); # British time stamp, MS files dont like : chars
	$newname =~ s/\.txt$/$timestamp\.txt/; # Substitute .txt with timestamp.txt
	# print "Valid static file is $fullname\nfilesize $filesize1 after delay is $filesize2 at $timestamp\n";
	print "$fullname to be move as $newname\n";
	
	# do $proc1 || print STDERR "Could not find $proc1 - $! > $@"; # Run process perl script.  Error if wont compile is in $@
	# Note that if script called used exit command then this also terminated calling program so I just use 1; instead of exit 0;
	rename ($fullname , $newname) || die ("Error in moving $fullname"); # rename moves file but only within same file system
	writexlsx(); # Call subrouting to turn attout into xlsx
	}
closedir DIRATTOUT;


#### LOOK FOR VALID XLSX FILES APPEARING IN XLSX IN DIR #####
# print "\nLooking in directory $xlidir for a valid file e.g. attxxxxx.xlsx\n\n";
opendir(DIRXLSXIN, $xlidir) || die "can't opendir $xlidir: $!";
@dirlistxlsxin = grep {(!/^\.\.?$/) && -f "$xlidir/$_" && (/.xlsx$/) && (/^att/)} readdir(DIRXLSXIN);
# print "\n Beginning fnamein process: \n";
foreach my $fnamein (@dirlistxlsxin) 
	{
	print "Found file with correct pre & postfix >  ${fnamein} \n"; # Each valid data element in xlsx in dir
	my $namelen = length ${fnamein}; # filename lenght including extension
		if ($namelen > $flimit)	{next} # skip if filename exceeds $flimit charaters
	# print "file name length is $namelen \n";
	my $fullname = "$xlidir/${fnamein}";
	my $filesize1 = -s $fullname; # -s is a perl file operator that returns the file size in bytes
		if ($filesize1 < 10 || $filesize1 > 1000000){next} # if less than 10 bytes or larger than 1M it can be skipped
	select(undef, undef, undef, 0.5); # wait half a second then check file size again
	my $filesize2 = -s $fullname; 
		if ($filesize1!=$filesize2) {next} # skip if file size is NOT the same after delay
	#Optional check to see if file has been closed	- file handle should be unopend and tell will warn without no warnings exclusion	
		if(tell(${fnamein}) != -1) {print "\n $fullname is open - skipping this file until its closed\n";
					next;
					}
					
	$newxlsx = "$vcdir/${fnamein}"; # Define new name based on existing name but in the valid candidate directory
	my $timestamp = strftime( '_%d%m%Y_%H%M%S', localtime ); # British time stamp, MS files dont like : chars
	$newxlsx =~ s/\.xlsx$/$timestamp\.xlsx/; # Substitute .txt with timestamp.txt
	# print "Valid static file is $fullname\nfilesize $filesize1 after delay is $filesize2 at $timestamp\n";
	print "$fullname to be move as $newxlsx\n";
	
	# do $proc1 || print STDERR "Could not find $proc1 - $! > $@"; # Run process perl script.  Error if wont compile is in $@
	# Note that if script called used exit command then this also terminated calling program so I just use 1; instead of exit 0;
	rename ($fullname , $newxlsx) || die ("Error in moving $fullname"); # rename moves file but only within same file system
	# print "\nCallin writeattin sub here will use new name $newxlsx\n";
	readxlsx();
	}




closedir DIRXLSXIN;

sleep 1; # Run this program every second
}


__END__

You may need to run this script using sudo to access other users shares

For the pi, create the users:

sudo useradd -m cadbox -G users
sudo smbpasswd -a cadbox
sudo passwd cadbox
password set to cadbox for samba and CADBOX for UNIX

useradd -m creates the users home directory if it does not exist. 
-G is supplementary groups the user is also a member of.

/etc/group should then show the users group has pi and sharebox as belonging to this group
pi@raspberrypi ~ $ id cadbox
uid=1001(cadbox) gid=1002(cadbox) groups=1002(cadbox),100(users)


/etc/samba/smb.conf needs to be set up for the shares:
##### Authentication #####
   security = user

 [cadbox]
        path = /home/cadbox
        comment = cadbox user home directory
        writeable = yes
        valid users = cadbox


