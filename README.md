## dbDotCad
An experiment with MongoDB using CAD attributes as the data set

\# X-Clacks-Overhead: GNU Terry Pratchett  
use humour;  
\# And don't ride in anything with a Capissen 38 engine  

### dbDotCad - the readme  
$VERSION = 0.046    
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

Tha authir cannot spell and his werk is full of typos... however there are a couple of intentional variations.  AutoKAD is produced by AUTODESC - if spelt correctly these are trademarks of a well known (and fantastic) product from a well known company.  The alternative spellings avoid copyright issues and may prevent search engines picking up this document.  Some AutoKAD commands will be explained but this is not a CAD tutorial. dbDotCad is not about CAD, its about databases, programming and interfacing to MongoDB with CAD as the data source.  There are lots of good tutorials for AutoKAD.  This is not one of them. 

**Why use familiar acronyms in a different context?**

Famous acronyms are easier to remember.  Any short combination of letters will have several acronyms.  CPD, CSI - see what they usually mean via the [acronym finder] (http://www.acronymfinder.com).

### THE CONCEPT OF CONNECTIVITY

A connection exists between a start point and an end point.  It could be a pipe, or a cable or a fiber.  It could carry one service, or many.  
In complex installations involving many interconnections, the cable/pipe/fiber will have an identifying number/name.  It will be physically labelled at each end and possibly several places along its length.  There are many connecting topologies, some involving loops; however, the physical implementation uses multiple cables/fibers/pipes the ends of which need to be identified in addition to defining their place in a circuit/system.   Many name and numbering conventions exist and the database implementation should be flexible and accommodating.  
Depending on the application there are several ways of describing connectivity relationships.  
Client Server, Master Slave, Peer to Peer, Host to Controller...  
The adopted standard for this implementation is Source to Destination.  Where a connection branches from one to  many, that branching point is the Source.  On the end of the branch is the end point, Destination.  The Destination may branch onwards, so for the next connection it's output can become the Source to the next Destination.  
A network switch connecting to several servers and workstations is the Source.  
A header tank feeding several irrigation channels is the Source.  
A distribution amplifier sending RF to several receivers is the Source.  
A microphone is the Source to the pre amp.   
The pre-amp output is the Source to a power amp.  
The power amp is the Source to the speaker.  
As a convention to defining connectivity **the Source will always be defined first** & matched to the Destination.

The Database can be used to provide next in sequence numbers/names by keeping track of the next in sequence running number.  
It should also be possible to 'seed' the provided sequence (at the expanse of redundant number space).
Further development could allow 'subnetting' of number space.  
Humanly readable and memorable conventions are preferable.

#### DbDotCad CONNECTION DEFINITIONS AND HOUSE RULES

**CS** = Connection segment.  A line on the drawing between two connection points.  
**CSI** = Connection Segment Identifier.  A visible drawing attribute representing the cable/pipe number etc.  
**NI** = Node Identifier.  A visible drawing attribute representing an item of equipment the CSI is connecting to.  
**CPS** = Connection Point Source.  Usually a connector/plug/socket/terminal. A drawing block (BLOCKNAME, CPS_<CPNAME>) and associated attributes including the CSI.  
**CPD** = Connection Point Destination.  Usually a connector/plug/socket/terminal. A drawing block (BLOCKNAME, CPD_<CPNAME>) and associated attributes including the CSI.  
**NODE** = Node.  Usually an item of equipment (but could be a simple T-Piece).  A nested block (BLOCKNAME, NODE_<NODENAME>) containing Connection Point blocks and associated attributes.  

USUALLY INVISIBLE ATTRIBUTE NAMES  
**HANDLE** = automatically created attribute identifier  
**BLOCKNAME** = automatically created block name field  
**TITLE** = field used by dbDotCad as a document identifier  
   
OPTIONALLY VISIBLE ATTRUBUTES  NAMES   
**CSI** = Connection Segment Identifier (cable number).  
**NI** = Node Identifier (equipment).  
**UDC** = User Defined Comment (free text field).   
**STATUS** = Status.   A single character only. X for not connected, ! for faulty or out of service.  
   
Node is from the Latin nodus, meaning 'knot'.
When a drawing is created, the Connection Point Source/Destination (CPS or CPD) will be a block with a unique database name and associated attributes as meta data.  Connections may have a mass of configuration information (Configuration Items) that would not normally be visible on a drawing and will be handled independantly within the database.  Drawing block attributes are limited to only those which may need to be visible or used to identify the block to the database.  The connection point will use arrows to represent the signal direction or flow.  Simplex connections will have a single arrow.  Duplex connections will be represented by two way arrows.  Connections forming part of a loop will have double arrows in the appropriate direction.  In the case of simplex connections, these typically 'enter' on the left and 'exit' on the right of a node.  Jackfields traditionally have outputs (sources) above inputs (destinations).
Each Connection Point will have the Connection Segment Identifier (CSI), typically a cable number, as an attribute. This would normally be visible on the drawing.
Items of equipment form nodes. Each node requires a unique database name, the Node Identifier (NI) and will be a nested block with BLOCKNAME = ND_<NODENAME> containing the connections.  CPS/CPD blocks are used as part of the Node block.
All blocks will contain keys for HANDLE (automatically added by AutoKAD), BLOCKNAME, then TITLE and FNAME followed by attributes specific to the block.  

IP information may be needed on a drawing.  In this case CIDR house rules apply (Classless Inter-Domain Routing notation).  [CIDR Explained] (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)

#### CONNECTIONS FOR NETWORK AND A/V/CONTROL

    <Type description e.g. net>-<Sub Type e.g. ana, dig, 1g>-<Block description e.g. pinsrc, pindst>_<Version e.g. 001>  

net-1g-pinsrc_001  

Type:  

tgf = 10G Ethernet over Fibre optic  
net = Ethernet including iscsi over cat cable, rj45  
fib = Fibre channel  
fcl = Fibre channel arbitrated loop  
tax = Twinax based connection such as Infiniband and UCS intterconnects, ucs, inf  
vid = Video analogue or digital ana, dig  
aud = Audio analoghe or digital ana, dig  
ctl = Control including serial RS422/485/232  
kvm = Keyboard Mouse & KVM extensions  
usb = USB direct or extended, 2.0, 3.0  
dpt = Display port, sub type can be thunderbolt tb_, miN  
vga = VGA or SCART  
gpi = GPI  
pwr = Power DC, AC  
asi = ASI  
rf_ = RF  
dvi = DVI  
hdm = HDMI  
tel = Telephone, PSTN  
opt = optical bundle, number of cores  

Sub Type:  

non =  no specific variation or the expected standard connection/connector  


### GETTING STARTED

On Ubuntu desktop or server (ideally a clean install - running in a VM) ...

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
6.  As root run ddc_builder_vx.pl   
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
8.  This installation of mongodb will not run at boot time unless startup.sh is executed and will add an @reboot line to the crontab
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
It is best practice is to create naming and numbering systems which follow a logical hierarchy. 
Based on some real world naming, ddc will adopt the following document naming convention for the CAD drawings.  

The Title will contain will contain a unique document reference:

N-N-N

Where N is Numeric, one or more numbers, no~spaces.  N must contain at least one number and each number is separated by hyphens.   
There must be no other characters used in the name.  

The File name will contain the numeric, hyphen separated, Document Title with an alphabetical revision identifier then a friendly name:

N-N-N-A_friendlyname.dwg

Where A is an upper case alpha, one or more letters, no~spaces.  This revision identifier must contain at least one alphabetical character.
The hyphens and underscore must be present and are used as part of a file/title name integrity check.

NUMERIC~AREA~CODE`-`NUMERIC~DOC~TYPE~GENERAL`-`NUMERIC~DOC~TYPE~SPECIFIC`-`ALPHA~REVISION~IDENTIFIER`_`   
followed by a friendly name and typically the .dwg file extension

This will be checked with the regex ^[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.*
The configuration file will allow 3 different regex matches to be used in cases where multiple naming conventions may exist.  

The Title is included as the beginning of the file name which may also include a descriptive name which may contain spaces.
The descriptive part of the name will not be used by the database for identification.  This is only for by humans who sometimes use white space in file names.
It is mandatroy to link the Alphabetical revision part to the name via an underscore to the description.

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
Block attribute data (meta data) is independent of the drawing.  
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
DDC adopts this method and requires a strict naming standard as above.

The first row in the file contains column headers that identify the data to ATTIN. 
The first two columns are always labelled HANDLE and BLOCKNAME as exported by ATTOUT (and required by the dxf standard).
DDC requires the next attribtue to be TITLE and to identify the docuocument.  

The remaining columns in the file are labelled with attribute tags as they appear in the drawing. 
Numbers are added to duplicate attribute tags to ensure that they are unique. 
It is useful (best practice) to make one of attributes the drawing identifier and to create a block name including a version number - it is usual to modify the blocks over time and this needs to be correctly identified by the program/database.

The header row in a file created by ATTOUT would look like this if a badly designed block used the TITLE tag twice:

HANDLE BLOCKNAME TITLE ATTRIBUTE1 ATTRIBUTE2 TITLE(1)

There is a column for each attribute from all selected blocks, 
attribute labels that do not apply to a specific block are indicated with 
`<>`
in the cells that do not apply.

The handle is an id automatically generated and unique to each block, ONLY FOR THE ORIGINATING DRAWING.  
The `ATTOUT` command adds a preceding apostrophe/single quote character to the HANDLE data which can be a useful validity check.
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

### dbDotCad block _id
Obviously, a single drawing has no way of knowing the handles used for other drawings.  
For migration into a database, some additional data identifying the (uniquely named) drawing file is necessary.  
This can be the file name (or part thereof) and/or the drawing title.  In our examples the N-N-N part of the title and/or file name will be used.   
The attout handle always starts apostrophe and has a 3 digit or larger hex value.  As the apostrophe is a useful chek, dbDotCad preserves this as part of the database_id.  The appended document identifier is added after the handle using a + character as a separator so the _id becomes 'handle+docname e.g. '12BFE+123-23-1234

### RELEVANT AUTOKAD COMMANDS 

AutoKAD commands can be in upper or lower case.  They can also be found as an icon/ribbon/menu but these notes will simply use the command line.  The help pages are excellent so use them.

#### Define the Document Title
Open a drawing or drawing template, then define the Document Title in
`DWGPROPS`
or File -> Drawing Properties... Summary tab

#### Creating a block
By creating an identification block with a Title, and optionally Subject and Filename attributes, this can be picked up during an export in cases where the existing blocks have not included this information (as is best practice).  The HANDLE is automatically created and populated.  The block name is also mandatory with the reserved name of BLOCKNAME.  The value is a user choice but another best practice is to incude a version number after the name.

`BEDIT`
In the block to create or edit field, give the block a name 'DDC_ID_V1'
Draw something and maybe add some text and create an attribute definition  
`ATT`
The attribute definition window should appear.  
In the Tag field, name the attribute key, for example 'TITLE'
(TITLE will be the key, the value will be the document Title field)  
In the Default drop down select Title (format none or define as desired).  
In the Mode area, it's possible to not see this on the drawing by ticking Invisible.  
Position the text within the block as necessary (even if its invisible)  
Click OK  
Repeat to add attributes for Filename if required Subject.  
Click on Close Block Editor and save the change.  
To edit an existing block, repeat the bedit command and select the block.  
To change the order of the attributes, use `BATTMAN` (requires full version of AutoCAD if below 2010).  This block attribute manager is also useful for editing/synchronising and checking all blocks within the current drawings.  

It is also possible to convert existing parts of a drawing to a block with the `BLOCK` command

Variables that display in the drawing are 'Field Text'.  To distinguish this from drawing text (which is part of the drawing and not metadata about the block it belongs to), AutoKAD places this text within a grey (none printing) mask.  This grey mask can be turned off with the `FIELDDISPLAY` by setting the value to `<0>`  

#### To insert the block
`INSERT`
In the Name drop down find the block just created 'DDC_ID_V1'
The existing Title data will appear as default.  Press enter (or right click) to accept each item as displayed or edit if required.

#### Selecting all blocks
Selection is for which ever drawing space (Model or Paper) currently active.
Most 'real' work is done in Model. This is where block attributes to be exported into the database will normally reside.
`Ctrl + A`, selects All and the command, `ATTOUT` performs an attribute export of all selected blocks.
From model space, (if not in model space the command is `MS`) it is also possible to filter specific blocks our use the quick select command, `QSELECT`
From the Object type, select Block Reference. Leave 'Apply to:' as Entire drawing. Click OK.

#### Extracting Block Attributes
Select the required blocks (Ctrl + A selects all)
`ATTOUT`
Edit the file name and location as desired.
Click Save.

`ATTOUT` is a LISP express tool installed by default with AutoKAD 2008 upwards to export the attributes of selected blocks.
`ATTIN` performs the opposite function.

For repeated use of a block, create a drawing with just the blocks (known as a block library drawing).
Open drawings or block library drawings can be used to add blocks to new drawings via the AutoKAD DesignCentre   
`ADCENTER`   
Select from the Folder or Open Drawings tab.

#### Attribute HANDLE & Databases
The HANDLE is not sufficiently unique to identify the block within a database.  HANDLE and TITLE can be concatenated to create a unique primary key,  _id.  For ease of reading, a + character is used as the separator between the handle and title fields.  As an additional aid to identification, the leading apostrophe created by attout is retained.  For example _id will become, 'HANDLE+TITLE and will look something like this: '35068+1234-5678-9012   
If drawing title or file name was not included in the block attributes then the relevant part of the file name (which includes the document title) can be extracted from the attout.txt file name. Typically, the columns as seen by the database then become:  

_id  BLOCKNAME  ATTRIBUTE1  ATTRIBUTE2  ATTRIBUTE3  

where _id = HANDLE+TITLE

#### Bulk import into database
mongoDB has a bulk import function and will accept javascript as an command line argument to the mongo command.
The attout format can easily be modified to comply with bulk import function.  For example, here the attout data becomes variable attout:  

`var attout = db.collection_name.initializeUnorderedBulkOp();`
`attout.insert( { "_id": "'35068+1234-5678-9012", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA01A", "LOCATION": "ROOM2/A01", "BRAND":"MEGAUNLIMITED" });` 
`attout.insert( { "_id": "'35069+1234-5678-9012", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA02A", "LOCATION": "ROOM2/A02", "BRAND":"MEGAUNLIMITED" });` 
`attout.insert( { "_id": "'35071+1234-5678-9012", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA04A", "LOCATION": "ROOM2/A04", "BRAND":"MEGAUNLIMITED" });` 
`attout.insert( { "_id": "'35072+1234-5678-9012", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA05A", "LOCATION": "ROOM2/A01", "BRAND":"MEGAUNLIMITED" });` 
`attout.insert( { "_id": "'35073+1234-5678-9012", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA06A", "LOCATION": "ROOM2/A06", "BRAND":"MEGAUNLIMITED" });` 
`attout.execute();`

If the modified attout.txt is saved as a new file, typically with a .js extension this can be passed to the mongo client:
`mongo bulkinsert_example.js`

mongoDB will automatically reject a duplicate _id.  This is not an error and for this application is the desired behaviour.  
The first import will succeed and can be used to initially populate or seed desired fields.  From this point onwards it is necessary to manipulate the data from within the database itself.  The databases is King and should always be this way.  Future attout operations will provide the _id for a query but only new _ids will add data to the database. 


#### Attributes and nested blocks
When blocks are nested, clicking on the block only presents attributes for the *parent* block.  Similarly using ATTOUT on a nested block only captures attributes from the *parent* and not the *children* within.
If the *parent* block is exploded then attributes of the *children* become visible.  Third party routines may exist to extract attributes from nested blocks but it is not possible with Express Tools and a default installation.  

For nested blocks containing other blocks defining connection points, it is possible to make a filtered selection of these within a drawing and then EXPLODE prior to using ATTOUT.  In this case consider defining colours BYBLOCK.

See also, third party lisp routines from:   
http://www.lee-mac.com/macatt.html   
http://www.lee-mac.com/attributecolour.html   
and check out the standard AppLoad and AttCol commands


#### Final thoughts 
I am not discouraged, because every wrong attempt discarded is another step forwards.   
Thomas Edison.   

There ain't no such thing as plain text.   
Sense and reason from Joel: [Unicode explained](http://www.joelonsoftware.com/articles/Unicode.html)
