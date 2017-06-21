## dbDotCad
An experiment with MongoDB using CAD attributes as the data set

use strict;   
\# X-Clacks-Overhead: GNU Terry Pratchett  
use humour;  
\# And don't ride in anything with a Capissen 38 engine  

### dbDotCad - the readme  

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
After looking for a MongoDB API, DreamFactory came up as an application worth a test drive.
Initially using Ubuntu as the OS, Perl & JavaScript.
MongoDB will be used to store CAD metadata and for drawing history/version tracking.
Data needs to be manipulated in spreadsheets using xlxs format.
CAD attributes (metadata) will use the DXF standard.
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

Any connection usually involves two parts.  Typically, some form of plug and some form of socket. It has been known for wring systems to cheat a little here and assume equipment has the appropriate connection and the drawing simply defines the required interconnection without the ability to ensure the equipment block and the connection match.  In this case the connecting association is with the equipment block and not individual connecting points on the block.  Both approaches should be supported.  Note that wiring schedules should always be from the perspective of the cable.  If a male connector is defined in a schedule, this implies male end on cable and not a male on the equipment which would require human interpretation to fit the correct connector.

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
**HANDLE** = automatically created attribute identifier, unique for each block in a drawing   
**BLOCKNAME** = mandatory block name field, should contain a version number for revision identification, no leading or trailing spaces should be used  
**TITLE** = field used by dbDotCad as a document (drawing) identifier  
**ALIAS** = field used by dbDotCad as a friendly name for connection name    
**UDC** = User Defined Comment (free text field).   
**COLCABLE** = Cable colour
**COLSLEEVE** = Sleeve colour if used
**

OPTIONALLY VISIBLE ATTRUBUTES  NAMES   
**CSI** = Connection Segment Identifier (cable number).  
**NI** = Node Identifier (equipment).  
**STATUS** = Status.   A single character only. X for not connected, ! for faulty or out of service.  
**LOCATION** = Location of the connection.  Site/Room/Rack/Rail/Chassis/Board  
**TOFROM**  = block_id from the connection block (HANDLE+TITLE)


Node is from the Latin nodus, meaning 'knot'.
When a drawing is created, the Connection Point Source/Destination (CPS or CPD) will be a block with a unique database name and associated attributes as meta data.  Connections may have a mass of configuration information (Configuration Items) that would not normally be visible on a drawing and will be handled independantly within the database.  Drawing block attributes are limited to only those which may need to be visible or used to identify the block to the database.  The connection point will use arrows to represent the signal direction or flow.  Simplex connections will have a single arrow.  Duplex connections will be represented by two way arrows.  Connections forming part of a loop will have double arrows in the appropriate direction.  In the case of simplex connections, these typically 'enter' on the left and 'exit' on the right of a node.  Jackfields traditionally have outputs (sources) above inputs (destinations).
Each Connection Point will have the Connection Segment Identifier (CSI), typically a cable number, as an attribute. This would normally be visible on the drawing.
Items of equipment form nodes. Each node requires a unique database name, the Node Identifier (NI) and will be a nested block with BLOCKNAME = ND_<NODENAME> containing the connections.  CPS/CPD blocks are used as part of the Node block.
All blocks will contain keys for HANDLE (automatically added by AutoKAD), BLOCKNAME, then TITLE and FNAME followed by attributes specific to the block.  

IP information may be needed on a drawing.  In this case CIDR house rules apply (Classless Inter-Domain Routing notation).  [CIDR Explained] (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)

#### CONNECTIONS FOR NETWORK AND A/V/CONTROL

Attribtue tags must be in upper case and cannot contain spaces
Block names can be in lower case and can contain spaces
Either may at some point become a worksheet name so keep within Excel namespace.

    <Type description e.g. Net><Sub Type e.g. A (Analogue), D (Digital), 1G, 10G>-<Block description e.g. CPS CPD>_<Version e.g. 1>  

Net1G-CPSV1  Network 1G Connection Point Source V1   
Net1G-CPDV1  Netwrok 1G Connection Point Destination V1   

Mixed case makes these easier to read and keeps the block name shorter if used in as a worksheet name.  The Connection Point & version part could be masked in the future to make this easier to present.

Type examples:  

10G = 10G Ethernet or Fibre Channel over Fibre optic  
Net = Ethernet including iscsi over cat cable, rj45  
Fib = Fibre channel switched fabric
Fal = Fibre channel arbitrated loop  
Tax = Twinax based connection such as Infiniband and UCS intterconnects, ucs, inf  
Vid = Video analogue or digital ana, dig  
Aud = Audio analoghe or digital ana, dig  
Ctl = Control including serial RS422/485/232  
KVM = Keyboard Mouse & KVM extensions  
USB = USB direct or extended, 2.0, 3.0  
DP = Display port, sub type can be thunderbolt tb_, miN  
VGA = VGA or SCART  
GPI = GPI  
Pwr = Power DC, AC  
ASI = ASI  
RF = RF  
DVI = DVI  
HDMI = HDMI  
Tel = Telephone, PSTN  
Opt = optical bundle, number of cores  

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
11. Install the DreamFactory LAMP stack using bitnami (includes MongoDB, MySQL and Postgress but with NginX as the web server)

### DreamFactory
It is easy to use the bitnami image https://bitnami.com/stack/dreamfactory/installer#linux
The ddc install script downloads this, chmod 755s the image and runs the install. 
For now there will be two instances of Mongo to play with. 
Change the DreamFactory web port to 8080 and Mongo to 27080 (as 80 and 27017 are already in use by ddc). 
For DreamFactory Mongo, installs to installs by defautl to: /opt/dreamfactory-<version.number>/mongodb/bin 
but it is possible to specify the install path (/opt/dreamfactory seems sensible).    
Files are also accessible via the API.  Path to New_Folder on server becomes:   
`/opt/dreamfactory/apps/dreamfactory/htdocs/storage/app/New_Folder`   
.txt files open in an exit window via the browser but need a chmod   



DreamFactory 2.0 supports forever session. 
By default it is disabled. 
To enable this uncomment the following line in .env file and set it to 'true'.   

`DF_ALLOW_FOREVER_SESSIONS=true`    

To make sure forever session is enabled, make the following API call.   
`GET http://{url}/api/v2/system/environment`   
Look for the following in your response.   
`...`   
`"authentication":{`   
`    ....`    
`    "allow_forever_sessions":true`    
`    ....`   
`}`   
`...`   

STARTING DREAMFACTORY
If dreamfactory was installed in opt/dreamfactory, start via the ctlscript.sh   
`sh /opt/dreamfactory/ctlscript.sh star`   

To remove login requirement, turn off security and restart   

`vim /opt/dreamfactory/mongod/mongod.conf`
`# Turn on/off security.  Off is currently the default`   
`noauth = true`   
`#auth = true`   
 
### dbDotCad Part1

write a ddc_upload.pl script to do the following:

1.  Read and verify parameters from a conf file.
1.  Implement a -c switch to create a default conf (to be used by the builder script)
Include path to attribute file, growing file check delay, enforce title, document count limit, error/status log names, database name.
2.  Scan watch folder (the SAMBA share) and check attribute file is present not growing.
3.  Process file creating unique id from handle and document number.
4.  Parse attribute file to create a js file.
5.  Bulk import to MongoDB.
6.  Optionally delete original files on success.
7.  Write status and log files

### NAMING CONVENTION FOR DRAWINGS 

It is best practice is to create naming and numbering systems which follow a logical hierarchy. 
Based on some real world naming, a unique document/drawing number, the TITLE (sN_N-N-N), will form the first part of the file name followed by an alphanumeric revision (upper case) followed by a friendly name to create the file name: 

sN_N-N-N-A_friendly name which may have spaces.dwg

N is Numeric, one or more numbers, no spaces; trailing zeros will be removed/ignored.  The N part must contain at least one number and each number is separated by hyphens; this is the document/drawing TITLE. TITLEs should be allocated so they are unique.  The revision must be upper case alpha characters only. The revision and the friendly name are not used by the database for identification.  The TITLE must exist in the AutoKAD, File -> Summary Tab -> Drawing Properties -> Title: to be available to the block and to be maintained if the file is saved as a pdf or .dxf 

The file name will contain the numeric, hyphen separated, document/drawing number with an alphabetical revision identifier then a friendly name.

Where A is an upper case alpha, one or more letters, no spaces.  This revision identifier must contain at least one alphabetical character.
The hyphens and underscore must be present and are used as part of a file/title name integrity check.   
Typical use for each field is:   

`Lowercase alpha immediately followed by NUMERIC SITE CODE`_`NUMERIC AREA CODE`-`NUMERIC DOC TYPE GENERAL`-`NUMERIC DOC TYPE SPECIFIC`-`ALPHA REVISION`_`FILE IDENTIFIER`.`FILE EXTENSION`      
Start with `s1_` for site 1 releated data     
Start with `x1_` added for cross site or site wide data for site 1, for example, inter-area cables    
Start with `e1_` added for enterprise wide data for enterprise 1, for example, host names     
Start with `t1_` templates for site 1, or `t0` for global templates with 0 for area code    
Start with `h1_` hostnames for site 1, or `h0` for global hostnames with 0 for area code   

The title will be checked with the regex ^(s|x|t|h)\d+_[0-9]+-[0-9]+-[0-9]+-[A-Z]+_.* or more concisely ^[sxth]\d+_([0-9]+-){3}[A-Z]+_.*   
The configuration file will allow 3 different regex matches to be used in cases where multiple naming conventions may exist.  ddc has to cope with a use case where existing naming had insufficient provision for the site code and different databases were used for different sites.  If the site code is missing (i.e the title is N-N-N-A not sN_N-N-N-A) the site code will be assumed to be s1_ by default.

The descriptive part of the name and the revision will not be used by the database for identification as part of a primary key.  This is only for by humans who sometimes use white space in file names.
It is mandatory to link the Alphabetical revision part to the name via an underscore to the description.


For example:
`s1_123-23-1234_C My Ace Design.dwg` for site 1
`s2_456-078-4567-AD_new_office_fist_floor.dwg` for site 2.   
The entry will become `s1_33-078-4567-AD_new_office_fist_floor.dwg` after processing.   
The `s1_33-078-4567` part will form the database key once concatonated with the block handle.

Note that CAD drawings must have a unique master name.  
i.e. the sN_N-N-N part MUST be unique.  The alpha revision identifier should be in UPPER CASE.
This format will be checked and enforced (using a regex that can be easily modified for other requirements)
For AutoKAD the .dwg extension is necessary.
Spaces in file names are common, even if undesirable these are allowed. Hyphens should be avoided as they can be interpolated by scripts as subtraction operators.
Names beginning with numbers cannot be used as mongoDB collection names without delimiting.
Leading zeros can be problematic.  Unfortunately the N-N-N format is common in drawing names.

The database ID for each Block will be created by appending the Handle to the sN_N-N-N part of the document title with an underscore separator. `'D57B8_s2-456-78-4567`        

This creates a totally unique reference for each block within the database and depending on the naming convention can provide a site and area reference.

Block identifying information will be unique so file revision data is not needed for block attributes.
Block attribute data (meta data) is independent of the drawing.  
Block definitions/revisions and tracking drawing changes are handled separately.

#### CREATING MONGO COLLECTIONS 

The prefix inter– means between or among.  
The prefix intra- means within.  

The database is intended to be split into collections for each area code of a site or by site wide collections in the case of inter-area connections. Separate drawings could be used for inter-site connection but any connection has to originate in one area and may land in a different area. If drawings are by area, this may be present on a different drawing. It must be easy to search the database for all connection information.   

For example site 1, area 20 will have blocks in the collection s1_20.  Inter-area connections (going between areas, could be considered Intra-site) need to be separated out into a different collections. The collection name becomes xN_0 where x is fixed to designate cross site, N is the site number. The area code is set to zero or could be used for different cross site collection on the same site. For example site 1 inter area connections will be in collection x1_0. Inter-area/Intra-site blocks will create a referred documents ID in a separate collection. These are then used to check data such as cable nubers as Mongo will not search between collections.

s0 is reserved for all sites, so for inter site connections, s0_inter collection could be used. To span collections for searching, there is a choice to be made between using multiple collections with id_ references or embedded documents. As the block attributes are to be a id_referened document separated by area code into collections then intra-area connections (connections within the same area) will be in the same collection.  Mongos $lookup (new in 3.2) performs a left-outer join with another collection. This creates new documents which contain everything from the previous stage but augmented with data from any document from the second collection containing a match BUT the 'from' collection cannot be sharded. To avoid issues where sharding may be deployed this approach was avoided.

#### FILE NAME V TITLE NAME

Many drawing and office applications allow the use of a document title.  
This will not change with the file name and is often maintained if the file format is changed, for example, if saved as a PDF.  
Ideally dbDotCad needs to adopt this as a best practice even if existing drawings and blocks have not been created to support a title field.
Optionally, the title name can be cross checked against the file name and the use of a document title enforced.
When first creating a drawing, ALWAYS define the Document Title using `dwgprops` or File -> Drawing Properties... Summary tab
and ensure this contains the unique document reference (N-N-N-N part of the file name) detailed above. 
Ideally every block definition should contain the title (and possibly file name) as attributes.  Although this is easy to do (see creating a block below), existing blocks may not follow this convention.  To make an existing document comply with the use of document titles, a single (possibly invisible) block can be added which simply contains just the title, file name and subject fields.  This will be captured if 'select all' is used before the attributes are exported and will be handled as an exception case where the document title is enforced but not contained in the existing blocks.

### ATTRIBUTE DATA FORMAT

The file written by ATTOUT is tab-delimited ASCII. These only include blocks with attributes.  In the following notes, assume that the term block refers to blocks with attribute data.      
The ATTOUT filename is the drawing file name with a .txt extension (but can be changed before saving).
Some file naming standards require the document title to be in the file name, this can be a useful cross check.   
DDC adopts this method and requires a strict naming standard as above.

The first row in the file contains column headers that identify the data to ATTIN. 
The first two columns are always labelled HANDLE and BLOCKNAME as exported by ATTOUT (and required by the dxf standard).
DDC would like the next attribute to be TITLE and to identify the document; however if a TITLE tag cannot be found then the filename of the attout file will be the same name as the drawing but with a .txt extension and could be used as a fall back name.  

The remaining columns in the file are labelled with attribute tags as they appear in the drawing. 
Numbers are added to duplicate attribute tags to ensure that they are unique. 
It is useful (best practice) to make one of attributes the drawing identifier and to create a block name including a version number - it is usual to modify the blocks over time and this needs to be correctly identified by the program/database.

The header row in a file created by ATTOUT would look like this if a badly designed block used the TITLE tag twice:

HANDLE BLOCKNAME TITLE ATTRIBUTE1 ATTRIBUTE2 TITLE(1)

It is possible to duplicate tag names in the same block but this is not valid formatting and duplicate tag strings appear red in the block attribute manager.

Each field (attribute/key name) is separated by a tab.  There is a column for each attribute from all selected blocks; 
data under each attribute/key that do not apply to a specific BLOCKNAME are indicated with 
`<>`
in the cells that do not apply.  If the entry for the tag value is empty then data between tabs of the ATTOUT file will be empty. i.e. No tag value results in a valid key and the data is empty.  If `<>` is used as the tag data, this will be saved in the ATTOUT operation but a warning `One or more records of data cannot be matched ...` will be shown during ATTIN operation. Where the attribute has `<>`, existing values will not be updated i.e. remaining data will not be overwritten.  Duplicating TAG names between different blocks is OK.  This is only listed once in the ATTOUT header.		

The handle is an id automatically generated and unique to each block, ONLY FOR THE ORIGINATING DRAWING.  
The `ATTOUT` command adds a preceding apostrophe/single quote character to the HANDLE data which can be a useful validity check.
Within AutoKAD it is possible to view the HANDLE data using LISP to show entity values for a selected object. Turn on the command line dispaly (ctrl+9) if this is not showing.  ctrl+9 will turn it off again.   
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
key HANDLE, value `'12BFE`    
The Entity handle is a text string of up to 16 hexadecimal digits.  For [more information of group codes] (http://www.autodesk.com/techpubs/autocad/acad2000/dxf/group_codes_in_numerical_order_dxf_01.htm) just Google for `dxf group codes`.   
    
It is possible to select or zoom to an entity (block) by using the HANDLE identifier.   
Issue the command SLELECT or ZOOM (_SELECT or _ZOOM if not using an English version of AutoKad). If zooming, first select O for object, then enter `(HANDENT "1234")` where 1234 is the HANDLE identification, without the apostrophe added by the ATTOUT command. Enter to take the HANDENT entry and Enter again to perform the zoom or selection.  
    
It is planned to separate out all the BLOCKNAMES found onto a different spreadsheet tabs.  BLOCKNAMES will be trimmed to remove leading or trailing spaces.   
A current implementation has only limited blocks which will be treated as special cases, these are:   
NAME (the default if the block is not named)  
PINL   
PINR   
Other blocks used in surrounds need no special attention.


### dbDotCad block_id
Obviously, a single drawing has no way of knowing the handles used for other drawings.  
For migration into a database, some additional data identifying the (uniquely named) drawing file is necessary.  
This can be the file name (or part thereof) and/or the drawing title.  In our examples the sN_N-N-N part of the title and/or file name will be used.   
The attout handle always starts apostrophe and has a 3 digit or larger hex value.  As the apostrophe is a useful chek, dbDotCad preserves this as part of the database_id.  The appended document identifier is added after the handle using a + character as a separator so the MongoDB primary key _id becomes 'handle_drawingnumber e.g. '12BFE_s1_123-23-1234  
This will be know as the **block_id** and becomes the primary key for the database.  Mongo allows the apostrophe (single quote character) in an id but not the double quote that would need delimiting when used in JSON.  Note that mongo field names cannot contain a period character (in our case this is the tag name) and needs replacing with the unicode equivalent \uFF0E   


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
This is also accessible from the toolbar as, Express > Blocks > Export Attribute Information.

`ATTOUT` is a LISP express tool installed by default with AutoKAD 2008 upwards to export the attributes of selected blocks.
`ATTIN` performs the opposite function.   
This is also accessible from the toolbar as, Express > Blocks > Import Attribute Information.

For repeated use of a block, create a drawing with just the blocks (known as a block library drawing).
Open drawings or block library drawings can be used to add blocks to new drawings via the AutoKAD DesignCentre   
`ADCENTER`   
Select from the Folder or Open Drawings tab.

Note that it is possible to have constant values in attributes and these do not export.  In AutoKAD AcDbBlockTableRecord owns all attribtue definitions.  AcDbBlockReference owns all the non-constant attributes (updated when inserting a block).  For constant vaues iterate AcDbBlockTableRecord.  For data to appear in the database, do not use constand values in the block.  Reserve constant vaules for blocks which are static and play not part in providing external metadata.       

#### Attribute HANDLE & Databases
The HANDLE is not sufficiently unique to identify the block within a database.  HANDLE and TITLE can be concatenated to create a unique primary key,  _id.  For ease of reading, an underscore _ character is used as the separator between the handle and title fields.  As an additional aid to identification, the leading apostrophe created by attout is retained.  For example _id will become, 'HANDLE_TITLE and will look something like this: '35068_s1_12-5678-9012   
If drawing title or file name was not included in the block attributes then the relevant part of the file name (which includes the document title) can be extracted from the attout.txt file name. Typically, the columns as seen by the database then become:  

_id  BLOCKNAME  ATTRIBUTE1  ATTRIBUTE2  ATTRIBUTE3  

where _id = HANDLE_TITLE

###Bulk import into database   

mongoDB has a bulk import function and will accept javascript as an command line argument to the mongo command.
The attout format can easily be modified to comply with bulk import function.  For example, here the attout data becomes variable attout:
`// Bulk import //`   
`// Switch to required db with getSibling so db name after mongo command not required`   
`// this will also create the database if it does not exist and will override *dbname* in mongo *dbname* scriptname.js`   
`db = db.getSiblingDB('database_name');`    
`var attout = db.attout_collection_name.initializeUnorderedBulkOp();`   
`attout.insert( { "_id": "'35068+1234-5678-9012-12", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA01A", "LOCATION": "ROOM2/A01", "BRAND":"MEGAUNLIMITED" });`   
`attout.insert( { "_id": "'35069+1234-5678-9012-12", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA02A", "LOCATION": "ROOM2/A02", "BRAND":"MEGAUNLIMITED" });`   
`attout.insert( { "_id": "'35071+1234-5678-9012-12", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA04A", "LOCATION": "ROOM2/A04", "BRAND":"MEGAUNLIMITED" });`   
`attout.insert( { "_id": "'35072+1234-5678-9012-12", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA05A", "LOCATION": "ROOM2/A01", "BRAND":"MEGAUNLIMITED" });`   
`attout.insert( { "_id": "'35073+1234-5678-9012-12", "BLOCKNAME":"MDU", "SYSTEMNAME":"172/MDUA06A", "LOCATION": "ROOM2/A06", "BRAND":"MEGAUNLIMITED" });`   
`attout.execute();`    

If the modified attout.txt is saved as a new file, typically with a .js extension this can be passed to the mongo client:
`mongo bulkinsert_example.js`

It is possible to script the find command to produce clean json by adding a forEach(printjson) loop, for example:   
`db.s1_2blocks.find ({"_id" : "'30C91_s1_02-20-3023"}).forEach(printjson);`   

js scripts can be run without specifying the database name if they contain the getSiblingDB definition, for example:  
`mongo attin.js`   
If you need to see the db selection and other commands execute, direct the script to the command:   
`monog < attin.js`   

mongoDB will automatically reject a duplicate _id.  This is not an error and for this application is the desired behaviour.  UnorderedBulkOp will not stop on error but the ordered output command will.   
The first import will succeed and can be used to initially populate or seed desired fields.  From this point onwards it is necessary to manipulate the data from within the database itself.  The databases is King and should always be this way.  Future attout operations will provide the _id for a query but only new _ids will add data to the database. 

###Querey via js
Another js file is created by the script - not that fields with periods in the database appear corretly when viewd by the client but have the unicode \uFF0E in the json output

`// block querey //`     
     
`db = db.getSiblingDB('BLOCKS');`   
`db.s1_10blocks.find ({"_id" : "'7D0D_t1_10-40-9956"});`   
`db.s1_10blocks.find ({"_id" : "'7D08_t1_10-40-9956"});`  

#### Collection names
The existing application has cable number collections which are site wide. 
In the future it would be sensible to limit this to site-area, with inter area cable numbers in a separate collection. 
Enterprise wide data such as hostnames, should be in a separate database. 
For now, blocks for site 1 will be in collection 1blocks, for site 002, 2blocks etc. Leading zeros will be removed.  Hyphens will be removed.
In the future, cable numbers could be subnetted by area code.   

#### Blocknames
Blocknames cannot be blank and must contain at least one character. They can contain spaces but this is best avoided.  Unlike attribute tags, they can be upper and lower case.
It is wise to add a version number to the block name and change this if tags are added, removed or changed, even if only the tag order is changed. 
Refefining blocks without changing the blockname or pasting blocks from one drawing to another can result in colliding blocknames with different attribute tag strings.  Handles remain unique to the drawing so attributes will still export and import successfully.  It is possible to check block/tag integrity by filtering the defined attribute tags to create a key string as a block_id:   
`,BLOCKNAME,tag1,tag2,tag3`   
`,BLOCKNAME,tag1,tag4,tag5`   
Such blocks would impact clean creation of spread sheets.  Beware.   

If block names are to appear as Excel worksheet names, these must match the Excel name space.  There is a 31 character limit and the sheetname cannot contain [ ] : * ? / \.  The same case insensitive name cannot be used.  This script removes these problem characters for spread sheet creation and replaces them a close alternative, { } . # > < respectively.  Sheetnames are truncated to 31 characters if necessary.  The database contains the original name.  The block is identified by the attribute tags and different blocks with the same name have the BLOCKNAME changed.  NAME would become NAME(1) NAME(2) etc.  Best practice requires a version number in the name, so avoid putting this in brackets and stick to underscores.  

#### Wiring scheduels from any pre-defined block names and tags
It should be possible to define the blocknames and tags to produce a schedlule, even if the block does not contain all the tag information:   

A wiring schedule row concatenates three parts:   
A general group based on the cable number, cable type, cable colour etc.  The database lookup is a find on the cable number.   
Friendly fields such as a cut column is added to provide a blank column for ticking off completed cables. 
As tags must be uppercase, fields not populated by the block attributes can contain lower case.   
NUM, CBLTYPE,  CBLCOLOR, BOOT, Lenght,  Cut   
A source group, here CPS is from block PINAR:   
LOCATION, SYSN, PIN, FROMTO, CONTYPE,   
A destination group, here CPD is from block PINAL:   
LOCATION, SYSN, PIN, FROMTO, CONTYPE, Comments      

For example the row in the spread sheet becomes:   
NUM, CBLTYPE,  CBLCOLOR, BOOT, Length,  Cut, PINAR (CPS), LOCATION, SYSN, PIN, FROMTO, CONTYPE, PINAL(CPD), LOCATION, SYSN, PIN, FROMTO, CONTYPE; Comments   
   
Create this whenever a CPD has a cable number NUM and run a find based on the collection for that site and area code, e.g. `db.s1_2blocks.find({ "NUM" : "V021234"})`   
   
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
