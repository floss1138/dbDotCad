## dbDotCad
An experiment with MongoDB using CAD attributes as the data set

\# X-Clacks-Overhead: GNU Terry Pratchett  
\# use humour;

### dbDotCad - the readme  
$VERSION = 0.0003    
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
Python 3 rocks and would also fit the use cases as would many other scriting solutions.
The scriting solution should be cross platform - it may need to run on Mac or Windows.

**Why Ubuntu?**

The author has been using the LTS versions for several years.
The build script should run on both server and desktop.
It is possible to produce build scripts for RHEL/Cent etc. if required.

**Will it run on a Rasberry Pi?**

It might but running an enterprise level database on a pi is never going to be speedy.
For testing, the average laptop will be fine.

**What is the expected deployment/scale/size?**

Users: < 50 making infrequent queries   
Documents in database: < 5 Million   
Storage: < 6TB   
This storage is intended for the CAD files and blocks,
the database is not expected to take significant part of this. 
dbDotCad can be run on a single server; in production this may not be wise.

### GETTING STARTED

On Unbuntu desktop or server (ideally a clean install - running in a VM) ...

1.  Download the build script ddc_builder.pl  
2.  Edit the scrip header (or accept the defaults)
The scripts creates a new named user (currently only one) held in the variable:  
`$user`   
A password protected user account and SAMBA share is created.
The passwords are prompted for when the script runs.
3.  Define the latest appropriate mongodb version as a link 
or accept the default in the header variable:
`$mongodb_latest`   
check the [mongodb download page](https://www.mongodb.org/downloads) for the latest version)
4.  Save the revised script.
5.  Before running the build, consider capturing the build output to a file   
`script ddcbuild_capture.txt`   
6.  As root run ddc_builder_vx.pl   
`sudo perl ddc_builder_vx.pl`   

mongodb is not installed from the Ubuntu repository as the 
purpose of this project is to experiment with mongodb &
to use the latest release in a way that can be easily removed or replaced.
Currently this is run as root - obviously not for production.  

ddcbuild will:

1.  Check if $user exists, if true offer to abort (as the script should only be run once)
1.  Update & upgrade Ubuntu
1.  Add useful commands not in the standard distribution such as 'tree'
1.  Create the $user and directories under /home/$user
1.  Add .dircolors and .vimrc to /root
1.  Add Perl Tidy, Perl Cirtic, App:cpanminus (cpanm), Regexp::Debugger (rxrx), Excel::Wirter, Spreadsheet::XLSX, Spreadsheet::Read
1.  Add 'samba' & create a safety copy of the clean smb.conf
1.  Set a smb and user passwd (these can be the same)
1.  Edit the smb.conf to allow follwing of symlinks and create a samba user & restart smbd
2.  Download, extract and install mongodb also creating the required /data/db directory
3.  Put the mongodb/bin into $PATH 
4.  Start mongod with the config opton providing the http interface
5.  Make a test connection to localhost 27017 
6.  Check smbstatus
7.  Create a start up script (as this installation of mongodb will not run at boot)
  



