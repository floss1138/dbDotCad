## dbDotCad
An experiment with MongoDB using CAD attributes as the data set

\# X-Clacks-Overhead: GNU Terry Pratchett  
use humour;  
\# And don't ride in anything with a Capissen 38 engine  

### dbDotCad - the readme  
$VERSION = 0.007    
> COPYRIGHT AND LICENSE    
> Copyright (C) 2015, floss1138  
> floss1138 ta liamg tod moc  

This project and documentation is free. 
You can redistribute it and/or modify it 
under the same terms as Perl 5.14.0.
It is distributed in the hope that it will be useful,
but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.
You are reading this at your own risk.
If you run this software you are also using it at your own risk.

#### FAQ:
**What is dbDotCad?**

An experiment with MongoDB using CAD attributes as the data set.
Initially using Ubuntu as the OS, Perl & JavaScript for scripting.
MongodB will be used to store CAD metadata and (drawing) file history/version tracking.
Data needs to be manipulated in spread sheets using xlxs format.
CAD attributes (metadata) will be use the DXF standard.
For more on DXF search for 'DXF Reference' or read the [reference manual](http://images.autodesk.com/adsk/files/autocad_2012_pdf_dxf-reference_enu.pdf)   
Shared storage between the client (running CAD) and server (running mongodb)
will use CIFS/SAMBA.   Web service will use Apache. 

**Why the name?** 

And I shall name it also unto you: db-dot-cad (pronounced deebee, dot, cad).  
Can be abbreviated to ddc.  
Oh, what a dull name - at the time of writing dbdotcad had no match in Google.

**Why MongoDB?** 

Well matched for document orientated data storage.  
Easy to deploy/develop.  
Makes the developer learn a bit of JavaScript.

**Why not use CouchDB?**

No need for massive world wide deployment but Couch would also fit nicely.
N1QL certainly helps if familiar with sql.  

**Why Perl?**

Well matched for regex and file based operations and has nice debug tools.  
Thanks to Damian Conway, the fantastic regex debug module Regexp::Debugger (rxrx).
The author of dbDotCad needs all the debug help he can find & Data::Dumper also comes in handy.
Python 3 rocks and would also fit the use cases as would many other scripting solutions.
The scripting solution should be cross platform - it may need to run on Mac or Windows.

**Why Ubuntu?**

The author has been using the LTS versions for several years.
The build script should run on both server and desktop.
It is possible to produce build scripts for RHEL/Cent etc. if required.

**Will it run on a Raspberry Pi?**

It might but running an enterprise level database on a pi is never going to be speedy.
For testing, the average laptop will be fine.

**What is the expected deployment/scale/size?**

Users: < 50 making infrequent queries   
Documents in database: < 5 Million   
Storage: < 2TB   
This storage is intended for the CAD files and blocks,
the database is not expected to take significant part of this. 
dbDotCad can be run on a single server; in production this may not be wise.

**Why the odd spellings?**

Tha authir cannot spell and his werk is full of typos... however there are a couple of intentional variations.  AutoKAD is produced by AUTODESC - if spelt correctly these are trademarks of a well known (and fantastic) product from a well known company.  The alternative spellings avoid copyright issues and may prevent search engines picking up this document.  Some AutoKAD commands will be explained but this is not a CAD tutorial. dbDotCad is not about CAD, its about databases, programming and interfacing to MongoDB with CAD as the data source.  There are lots of good tutorials for AutoKAD.  This not one of them. 

### GETTING STARTED

On Unbuntu desktop or server (ideally a clean install - running in a VM) ...

1.  Download the build script ddc_builderv#.pl  
2.  Edit the scrip header (or accept the defaults)
The scripts creates the new user 'alice' (currently only one) held in the variable:  
`$user`   
A password protected user account and SAMBA share is created.
The passwords are prompted for when the script runs.  
User & SAMBA passwords can be identical.  
3.  Define the latest appropriate mongodb version as a link 
or accept the default in the header variable:
`$mongodb_latest`   
Check the [mongodb download page](https://www.mongodb.org/downloads) for the latest version
4.  Save the revised script.
5.  Before running the build, consider capturing the build output to a file   
`script ddcbuild_capture.txt`   
6.  As root run ddc_builderv#.pl   
`sudo perl ddc_builder_vx.pl`   

mongodb is not installed from the Ubuntu repository as the 
purpose of this project is to experiment with mongodb &
to use the latest release in a way that can be easily removed or replaced.
Currently this is run as root - obviously not for production.  

ddc_builder will:

1.  Check if $user exists, if true offer to abort (as the script should only be run once)
1.  Update & upgrade Ubuntu
1.  Add useful commands not in the standard distribution such as 'tree' and 'git'
1.  Create the $user and various directories under /home/$user
1.  Add .dircolors and .vimrc to /root
1.  Add Perl Tidy, Perl Critic, App:cpanminus (cpanm), Regexp::Debugger (rxrx), Excel::Wirter, Spreadsheet::XLSX, Spreadsheet::Read.  Excel::Writer takes a while to compile, be patient
1.  Add 'samba' & create a safety copy of the clean smb.conf
1.  Set a smb and user passwd (these can be the same)
1.  Edit the smb.conf to allow following of symlinks and create a samba user & restart smbd
1.  Installs Apache with an Alias to the users log directory
2.  Download, extract and install mongodb also creating the required /data/db directory
3.  Put the mongodb/bin into $PATH 
4.  Start mongod with the config option providing the http interface
5.  Make a test connection to localhost 27017 to prove MongoDB installed OK
6.  Check smbstatus to prove samba installed OK
7.  Create a start up script (defined in $startup) startup.sh 
7.  Create a simple index page for the web service
8.  This installation of mongodb will not run at boot time unless startup.sh is executed, the script will suggest adding this to crontab as an @reboot line
9.  Write a javascript file to create and test the database ddc_create.js 
10. wget other scripts a needed from Github

### dbDotCad Part1

write a ddc_upload.pl script to do the following:

1.  Read and verify parameters from a conf file.
1.  Implement a -c switch to create a default conf (to be used by the builder script)
Include path to attribute file, growing file check delay, enforce title, document count limit, error/status log names, database name.
2.  Scan watch folder (the SAMBA share) and check attribute file is present not growing.
3.  Process file creating unique id from handle and title.
4.  Parse attribute file to create a js file.
5.  Bulk import to MongoDB.
6.  Optionally delete original files on success.
7.  Write status and log files

### NAMING CONVENTION FOR DRAWINGS
Based on some real world naming, ddc will adopt the following document naming convention for the CAD drawings.  

The Title will contain will contain a unique document reference:

N-N-N

N = Numeric up to 4 numbers, no spaces.  N must contain at least one number and separated by hyphens.

The File name will contain the Document Title with an alphabetical revision identifier and a friendly name:

N-N-N-A_friendlyname.dwg

A = Upper case alpha up to 4 letters, no spaces.  Must contain at least one alphabetical character.
The hyphens and underscore must be present and are used as part of a file/title name integrity check.

NUMERIC_AREA_CODE-  
NUMERIC_DOCUMENT_TYPE_GENERAL-  
NUMERIC_DOCUMENT_TYPE_SPECIFIC-  
ALPHABETICAL_REVISION_IDENTIFIER  


This Title information and  a descriptive name which may contain spaces.
The descriptive part of the name will not be used by the database for identification.
Link the Alphabetical part to the name via a mandatory underscore.

N-N-N-A_Descriptive name spaces allowed.extension

For example:
`123-23-1234_C My Ace Design.dwg` or
`456-78-4567-AD_new_office_fist_floor.dwg`

CAD drawings must have a unique master name.  
i.e. the N-N-N part MUST be unique.  The revision identifier should be in UPPER CASE.
This format will be checked and enforced (using a regex that can be easily modified for other requirements)
For AutoKAD the .dwg extension is necessary.
Spaces in file names are common, even if undesirable these are allowed.

The database ID for each Block will be created by appending the Handle to the N-N-N part of the document title.
This creates a totally unique reference for each block within the database.

Block identifying information will be unique so file revision data is not needed for block attributes.
Block attribute data (metadata) is independent of the drawing.  
Block definitions/revisions and tracking drawing changes are handled separately.

#### FILE NAME V TITLE NAME

Many drawing and office applications allow the use of a document title.  
This will not change with the file name and is often maintained if the file format is changed, for example, if saved as a PDF.  
Ideally dbDotCad needs to adopt this as a best practice even if existing drawings and blocks have not been created to support a title field.
Optionally, the title name can be cross checked against the file name and the use of a document title enforced.
When first creating a drawing, ALWAYS define the Document Title using `dwgprops` or File -> Drawing Properties... Summary tab
and ensure this contains the unique document reference (N-N-N part of the file name) detailed above. 
Ideally every block definition should contain the title (and possibly file name) as attributes.  Although this is easy to do (see creating a block below), existing blocks may not follow this convention.  To make an existing document comply with the use of document titles, a single (possibly invisible) block can be added which simply contains just the title, file name and subject fields.  This will be captured if 'select all' is used before the attributes are exported and will be handled as an exception case where the document title is enforced but not contained in the existing blocks.

### ATTRIBUTE DATA FORMAT

The file written by ATTOUT is tab-delimited ASCII.    
The ATTOUT filename is the drawing file name with a .txt extension (but can be changed before saving).
Some file naming standards require the document title to be in the file name, this can be a useful cross check.

The first row in the file contains column headers that identify the data to ATTIN. 
The first two columns are labelled HANDLE and BLOCKNAME. 

The remaining columns in the file are labelled with attribute tags as they appear in the drawing. 
Numbers are added to duplicate attribute tags to ensure that they are unique. 
It is useful (best practice) to make one of attributes the drawing identifier and to create a block name including a version number - it is usual to modify the blocks over time and this needs to be correctly identified by the program/database.

The header row in a file created by ATTOUT would look like this if a badly designed block used the DCC_TITLE tag twice:

HANDLE  BLOCKNAME  DDC_TITLE  DDC_FILENAME DDC_TITLE(1)

There is a column for each attribute from all selected blocks, 
attribute labels that do not apply to a specific block are indicated with 
`<>`
in the cells that do not apply.

The handle is an id automatically generated and unique to each block, ONLY FOR THE ORIGINATING DRAWING.  
The `attout` command adds a preceding apostrophe/single quote character to the HANDLE data which can be a useful validity check.
Within AutoKAD it is possible to view the HANDLE data using LISP to show entity values for a selected object.  
Command:  `(entget (car (entsel)))`
car returns first item in the list, group 5 is the handle.  
For example  
Command: `(entget(car(entsel)))`  
Select object: ((-1 . <Entity name: 7ef65b30>) (0 . "INSERT") (330 . <Entity
name: 7ef5dd18>) (5 . "12BFE") (100 . "AcDbEntity") (67 . 0) (410 . "Model") (8
. "TEXT_CON") (6 . "ACAD_ISO03W100") (100 . "AcDbBlockReference") (66 . 1) (2 .
"CONTYPE_F_V1") (10 400.0 384.5 0.0) (41 . 1.0) (42 . 1.0) (43 . 1.0) (50 . 0.0) (70
. 0) (71 . 0) (44 . 0.0) (45 . 0.0) (210 0.0 0.0 1.0))  
To find the handle associated with an ename, use the DXF 5 group of the ename's association list:  
Command: `(setq handle-circle (cdr (assoc 5 (entget ename-circle))))`  

When exported from AutoKAD, the block above would have   
key HANDLE, value '12BFE  
Obviously, a single drawing has no way of knowing the handles used for other drawings.  
For migration into a database, some additional data identifying the (uniquely named) drawing file is necessary.  
This can be the file name (or part thereof) and/or the drawing title.  In our examples the N-N-N part of the title and/or file name will be used.

### RELEVANT AUTOKAD COMMANDS 

#### Define the Document Title
Open a drawing or drawing template, then define the Document Title in
`dwgprops`
or File -> Drawing Properties... Summary tab

#### Creating a block
By creating an identification block with a Title, and optionally Subject and Filename attributes, this can be picked up during an export in cases where the existing blocks have not included this information (as is best practice).

`bedit`
In the block to create or edit field, give the block a name 'ddc_docprops'
Draw something and maybe add some text and create an attribute definition  
`att`
The attribute definition window should appear.  
In the Tag field, name the attribute key, for example 'DDC_TITLE'
(DDC_TITLE will be the key, the value will be the Title)  
In the Default drop down select Title (format none or define as desired).  
In the Mode area, it's possible to not see this on the drawing by ticking Invisible.  
Position the text within the block as necessary (even if its invisible)  
Click OK  
Repeat to add attributes for Subject and Filename.  
Click on Close Block Editor and save the change.  
To edit an existing block, repeat the bedit command and select the block.  
To change the order of the attributes, use battman (requires full version of AutoCAD if below 2010)  

It is also possible to convert existing parts of a drawing to a block with the `block` command

#### To insert the block
`insert`
In the Name drop down find the block just created 'ddc_tblock'
The existing Title data will appear as default.  Press enter (or right click) to accept each item as displayed or edit if required.

#### Selecting all blocks
Selection is for which ever drawing space (Model or Paper) currently active.
Most 'real' work is done in Model. This is where block attributes to be exported into the database will normally reside.
`Ctrl + A`, selects All and the command, `attout` performs an attribute export of all selected blocks.
From model space, (if not in model space the command is `ms`) it is also possible to filter specific blocks our use the quick select command, `qselect`
From the Object type, select Block Reference. Leave 'Apply to:' as Entire drawing. Click OK.

#### Extracting Block Attributes
Select the required blocks 
`attout`
Edit the file name and location as desired.
Click Save.

ATTOUT is a LISP express tool installed by default with AutoKAD 2008 upwards.
ATTIN performs the opposit function.

For repeated use of a block, create a drawing with just the blocks (known as a block library drawing).
Open drawings or block library drawings can be used to add blocks to new drawings via the AutoKAD DesignCentre   
`adcenter`   
Select from the Folder or Open Drawings tab.

#### Final thoughts 
I am not discouraged, because every wrong attempt discarded is another step forwards.   
Thomas Edison.   

There ain't no such thing as plain text.  Sense and reason from Joel:   
[Unicode explained](http://www.joelonsoftware.com/articles/Unicode.html)

