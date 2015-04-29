## dbDotCad
An experiment with mongodb using CAD attributes as the data set

\# X-Clacks-Overhead: GNU Terry Pratchett  
\# use humour;

### dbDotCad - the readme  
$VERSION = 0.0002    
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
Initially using Ubuntu as the OS, with perl and js for scripting.
mongo will be used to store CAD data and (drawing) file history/version tracking.
Data needs to be manipulated in spread sheets using xlxs format.
CAD attributes (metadata) will be in DXF
Google for 'DXF Reference' or read the [reference manual](http://images.autodesk.com/adsk/files/autocad_2012_pdf_dxf-reference_enu.pdf)   
Shared storage between the client (running CAD) and server (running mongod)
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
Python 3 rocks and would also fit the use case.  As would other scriting solutions.

**Why Ubuntu?**

The author has been using the LTS versions for several years.
The build script should run on both server and desktop.
It is possible to produce build scripts for REL/Cent etc. if required.

**Will it run on a Rasberry Pi?**

It might but running an enterprise level database on a pi is never going to be speedy.
For testing, the average laptop will be fine.

**What is the expected deployment/scale/size?**

Users: < 50 making infrequent queries   
Documents in database: < 50 Million   
Storage: < 6TB   
This storage is intended for the CAD files and blocks,
the database is not expected to take significant part of this. 
dbDotCad can be run on a single server; in production this may not be wise.

### GETTING STARTED

On Unbuntu desktop or server ...

1.  Download the build script ddc_builder.pl  
2.  The scrip creates a named user. Edit the header for the required user name  
`$user`   
This creates a password protected user account and SAMBA share.
3.  Define the latest appropriate mongodb version as a link in  
`$mongodb_latest`   
check the [mongodb download page](https://www.mongodb.org/downloads) for the latest version)

Consider capturing the build output to a file   
`script ddcbuild_capture.txt`   
As root run ddc_builder_vx.pl   
`sudo perl ddc_builder_vx.pl`   

mongodb is not installed from the Ubuntu repository as the 
purpose of this project is to experiment with mongo &
to use the latest release that can be easily removed or replaced.
Currently this is run a root - obviously not for production.  

