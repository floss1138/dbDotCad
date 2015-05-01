## dbDotCad
An experiment with mongodb using CAD attributes as the data set

\# X-Clacks-Overhead: GNU Terry Pratchett  
\# use humour;

### dbDotCad - the readme  
$VERSION = 0.0003    
> COPYRIGHT AND LICENSE    
> Copyright (C) 2015, floss1138  
> floss1138 ta liamg tod moc  

This project and documentation is free 
You can redistribute it and/or modify it 
under the same terms as Perl 5.14.0.
It is distributed in the hope that it will be useful,
but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.
You are reading this at your own risk.
If you run this software you are also using it at your own risk.

#### FAQ:
**What is dbDotCad?**

An experiment with mongodb using CAD attributes as the data set.
Initially using Ubuntu as the OS, perl & js for scripting.
mongodb will be used to store CAD metadata and (drawing) file history/version tracking.
Data needs to be manipulated in spread sheets using xlxs format.
CAD attributes (metadata) will be use the DXF standard.
For more on DXF search for 'DXF Reference' or read the [reference manual](http://images.autodesk.com/adsk/files/autocad_2012_pdf_dxf-reference_enu.pdf)   
Shared storage between the client (running CAD) and server (running mongodb)
will use CIFS/SAMBA.   Web service will use Apache. 

**Why the name?** 

And I shall name it also unto you: db-dot-cad (pronounced deebee, dot cad).  
Oh, what a dull name - at the time of writing dbdotcad had no match in Google.

**Why mongodb?** 

Well matched for document orientated data storage.  
Easy to deploy/develop.  
Makes the developer learn a bit of JavaScript.

**Why not use couch?**

No need for massive world wide deployment but couch would also fit nicely.
N1QL certainly helps if familiar with sql.  

**Why perl?**

Well matched for regex and file based operations.  
Thanks to Damian Conway, a fantastic regex debug module (rxrx/Regexp::Debugger).
The author of dbDotCad is not a programmer
and needs all the help he can find.
Python 3 rocks and would also fit the use case.
As would many other scriting solutions.

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
Currently this is run a root - obviously not for production.  

ddcbuild will:

1.  Check if $user exists
if true offer to abort (as the script should only be run once)
2.  Update Ubuntu
3.  Add .dircolors and .vimrc to /root
4.  Add Perl Tidy, Perl Cirtic, cpanm, Regexp::Debugger, Excel::Wirter, Spreadsheet::XLSX, Spreadsheet::Read
5.  Add samba
6.  Make a safety copy of the clean smb.conf
7.  Set the smb passwd
8.  Edit the smb.conf to allow follwing of symlinks and create a samba user
9.  Restart smbd



