#! /usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);
use English qw(-no_match_vars);
use Carp;
use IPC::Open2;

# floss1138 ta liamg tod moc
# COPYRIGHT AND LICENSE
# Copyright (C) 2015, floss1138.

# This program is free software; you
# can redistribute it and/or modify it under the same terms
# as Perl 5.14.0.

# This program is distributed in the hope that it will be
# useful, but without any warranty; without even the implied
# warranty of merchantability or fitness for a particular purpose.

our $VERSION = '0.0.33';

# SERVER BUILD SCRIPT FOR CADBox on Ubuntu server 12.04
# Installs mongodb, adds required perl modules, other Linux commands and Samba
# Creates a new Unix user $user and exports a Samba share for this users home directory
# THIS IS A BUILD SCRIPT AND IS INTENDED TO ONLY BE RUN ONCE
# run as root:

## USER DEFINED VARIABLES HERE ##

# Specify user name used to create both a local (Unix) account and a samba user
my $user = 'alice';

# Specify the path to the appropriate required mongodb binary here:
# (check https://www.mongodb.org/downloads for the latest)
# For legacy Linux (that old laptop) https://fastdl.mongodb.org/linux/mongodb-linux-i686-3.0.2.tgz
my $mongodb_latest =
  'http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1204-3.0.3.tgz';

# Specify path to smb.conf
my $smb_conf = '/etc/samba/smb.conf';

## SAMBA SHARE CONFIGURATION

# Add [global] parameters here:
# Create a variable containing smb.conf additions (substituted  by matching on [global])

my $globaladditions = << "GLOBAL";
[global]
   follow symlinks = yes
   wide links = yes
   unix extensions = no
GLOBAL

# Specify samba share additions, these are added at the end of the smb.conf file
# /home/$user will be created by this script and shared by samba

my $smb_additions = << "ADDITIONS";

[$user]
   path = /home/$user
   comment = $user user home directory
   writeable = yes
   valid users = $user

ADDITIONS

## START UP FILE

# Create a startup script file in /root for mongodb and other perl scripts
# To automate at boot add  '@reboot /root/startup.sh' to crontab

my $startup = << "START";
#!/bin/bash
sudo /root/mongodb/bin/mongod -f /root/mongodb/mongod.conf &
# sudo perl /home/user/script1.pl &
# sudo perl /home/user/script2.pl &

START

## --------------------------------------------------------------##
## PROGRAM STARTS HERE, DONT MESS WITH VARIABLES BELOW THIS LINE ##

# variable to hold contents of smb.conf file
my $smbconf;

# Find local ip address using hostname -I, and remove the new line

open2 my $out, my $in, "hostname -I"
  or die "hostname could not run";

my $ipaddress = <$out>;

chomp $ipaddress;

# date stamp when run to use as file name suffix
my $date_stamp = strftime( '%d%m%Y_%H%M%S', localtime );

print << "GREETINGS";
   
      *** WELCOME TO dbDotCad ****
         
   This script $PROGRAM_NAME V$VERSION 
   sets up an environment for dbDotCad on Ubuntu
   for this machine with IP address: $ipaddress
   Created and tested for Ubuntu 12.04 64 bit server 
   and 14.04 32 bit desktop.
   MongoDB will be installed from \n   $mongodb_latest \n
   By default, the user, $user, will be created. 
   It is necessary to create passwords for the user account and share access.
   The script will pause at these points.  Account and samba passwords can be the same.
   Run this script as root.  If not already doing so,
   consider capturing the script output to a file e.g. script build_capture.txt
   Press enter to continue or ctrl C to bail ...
  
GREETINGS

local $| = 1;    # Flush STDIO prior to wait
my $wait = <STDIN>;    # Wait for Enter response

# CREATE A USER
# Check if the user already exists - if it does this script has been run before!
# In this case there should be a bail out option.

# check group file for user
open my $GROUPFILE, "<", "/etc/group" or die "Cannot open /etc/group: $!";
while (<$GROUPFILE>) {
    if ( $_ =~ m/($user)/ ) {
        print
"\n $user user already exist - this setup script has probably been run before.\n At the risk of mangling the current installation with repeated configuration, press Enter to continue or ctrl C to cancel > \n\n";
        close($GROUPFILE);
        $wait = <STDIN>;
    }
}

# Create the $user, -m to create a new home directory and -G to add to secondary group
system("sudo useradd -m $user -G users");
print
"\n $user user created & added to users group.\n The home directory /home/$user was also created \n";

# CREATE DIRECTORIES

print "\n creating local directories within /home/$user/";

# /media/data is the automounted partition - called data.
# These directories are symlinked later.  Using UPPERCASE for symlinked directories
# Create the directory where mongodb binaries will reside:
# system ("mkdir /root/mongodb"); # This is now created by renaming the extracted mongodb directory
# Create the user directories
# mkdir -p will create the intermediate directories, -m sets the mode using the same arguments as the chmod command
system("mkdir -p -m 755 /home/$user/attout");
system("mkdir -m 755 /home/$user/attout_to_xlsx");
system("mkdir -m 755 /home/$user/xlsx");
system("mkdir -m 755 /home/$user/attin");
system("mkdir -m 755 /home/$user/xlsx_to_attin");
system("mkdir -m 755 /home/$user/attvalid");
system("mkdir -m 755 /home/$user/send_for_review");
system("mkdir -m 755 /home/$user/TESTFILES");
system("mkdir -m 755 /home/$user/TEMPLATES");
system("mkdir -p -m 755 /media/data/TESTFILES");
system("mkdir -p -m 755 /media/data/TEMPLATES");

# create symlinks from media mount point to local /home/$user - this is just for testing if smb can follow symlinks
system(
"sudo ln -s /media/data/TESTFILES/ /home/$user/media_TESTFILES && sudo ln -s /media/data/TEMPLATES/ /home/$user/media_TEMPLATES"
);


# change permissions (this will not change the symlink permissions itself, but the file pointed to, use chown -h for that)

system("sudo chown $user:$user /home/$user/*");
system("sudo chown $user:$user /media/data/*");
system("ls -al /home/$user");

# UNIX ENVIRONMENT - UPGRADE AND ADDITIONS

print "\n Updating with apt-get\n";
system("apt-get update");

print "\n Now upgrading..... \n";
system("apt-get upgrade");

print "\n Installing tree command\n";
system("apt-get install tree");

print "\n Installing git-core\n";
system("sudo apt-get install git-core");

# git-core has been renamed to just git

print "\n Installing apache2\n";
system("apt-get install apache2");

print "\n Linking into document home /var/www/ \n";
system("sudo ln -s /home/$user/send_for_review /var/www/sent_for_review");

print
"\n Changing the dark blue characters in the shell terminal to cyan for ls (configured with /etc/DIR_COLORS)\n";

# This is .dir_colors on some other systems
system("echo 'DIR 01;36' >> /root/.dircolors");

# Hash this bit out if you dont use vim...
print "\n Setting up vimrc for numbering and colorscheme ron \n";
system("echo 'set su' >> /root/.vimrc");

# colourscheme(s) ron and elflord seem to work with perl
system("echo 'colorscheme ron' >> /root/.vimrc");

print "\n Changing the shell for $user to bash \n";
system("chsh -s /bin/bash $user");

print "\n Copying the root user .bashrc and .dircolors to /home/$user \n";

# Config files for new users could be put in /etc/skel - need to test this
system("cp /root/.bashrc /home/$user");
system("cp /root/.dircolors /home/$user");
system("cp /root/ .vimrc /home/$user");
system("chown $user:$user /home/$user/.bashrc");
system("chown $user:$user /home/$user/.profile");

print "\n Listing the $user home directory \n";
system(" ls -aln /home/$user; tree /home/$user");

# PERL ENVIRONMENT

print "\n Setting up Perl Tidy\n";
system("apt-get install perltidy");

print "\n Setting up Perl Critic\n";
system("apt-get install perl-Task-Perl-Critic");

print "\n Installing cpanm\n";
system("apt-get install cpanminus");

# some server builds do not have 'make' by default
# the following modules require make to build
# apt-get will install a later version over an existing version if present

print "\n Installing 'make'\n";
system("apt-get install make");

print "\n Installing rxrx\n";
system("cpanm Regexp::Debugger");

# John McNamaras create XLSX format spreadsheets
print "\n Install Excel::Writer\n";
system("cpanm Excel::Writer::XLSX");

print "\n Install Spreadsheet::XLSX\n";
system("cpanm Spreadsheet::XLSX");

print "\n Install Spreadsheet::Read";

# The Read module had to be forced if an earlier version was present
system("cpanm -f Spreadsheet::Read");

# SAMBA ENVIRONMENT

print
  "\n Adding or updating, SMB/CIFS protocol for Windows interoperability \n";
system("apt-get install samba");

print "\n Provides SMB/CIFS file sharing with samba-common-bin \n";
system("apt-get install samba-common-bin");

print "\n Starting samba... \n";
system("service smbd start");

print "\n Make a copy of the /etc/samba/smb.conf file\n";
system("cp /etc/samba/smb.conf /etc/samba/smb.conf.$date_stamp");

print "\nSet smb passwd for $user\n";
system("sudo smbpasswd -a $user");

print "\nsmb password set for $user\n";
print "\nSet Unix password for $user\n";

system("sudo passwd $user");
print "\nUnix password set for $user\n";

# MODIFY smb.conf FILE
print "Adding global config for symlinks to smb.conf \n\n $globaladditions \n";

# open smb.conf for reading
if ( !open my $SMBCONF, '<', '/etc/samba/smb.conf' ) {
    print "\n  smb.conf would not open for reading \n";
}
else {
    print "\n reading smb.conf \n";

    # slurp smb.conf into $smbconf
    $/ = undef;

    $smbconf = <$SMBCONF>;

    # replace [global] with [global] and our additions
    $smbconf =~ s/\[global\]/$globaladditions/;

    # if required print the new file content to screen
    # print "$smbconf";

    close $SMBCONF or carp "Unable to close /etc/samba/smb.conf";

}

# Append $user share configuraton to smb.conf file

print
  "\n Adding $user additions: \n$smb_additions \n to end of smb.conf file \n\n";
$smbconf = $smbconf . $smb_additions;

# if required print the new file content to screen aganin...
print "$smbconf";

# open smb.conf for writing (overwriting the whole file) with the new content

print "\n Replacing smb.conf file.... \n\n";
if ( !open my $SMBCONF, '>', '/etc/samba/smb.conf' ) {
    print "\n  smb.conf would not open for writing\n";
}
else {

    # write new $smbconf  to the file handle
    print $SMBCONF "$smbconf";
    close $SMBCONF or carp "Unable to close /etc/samba/smb.conf";
}

# Restart samba to make new user config and password active

# On a RPi
# On Ubuntu server
# system ("sudo /etc/init.d/samba restart");
system("service smbd restart");
print "\nSamba restarted\n";

# MONGODB

# This script does not use apt-get, so the very latest build can be used
# This is installed to /root/mongodb and run stand alone
# This is not the way it should be run in production !
# It wont start from boot so add an @reboot to crontab if you need that

print "\n Now to download mongodb to /root/downloads, creating directory... \n";
system("mkdir -p /root/downloads && chmod 755 /root/downloads");

print "\n Fetching the latest mongo build with wget as mongodb.tgz \n";
system("wget -O /root/downloads/mongodb.tgz $mongodb_latest");

print
"\n gunzipping the mongodb.tgz and extract mongodb.tar \n (creates directory names from within the tar name) \n\n";

# Extract the tar from the tgz
system("gunzip /root/downloads/mongodb.tgz; ");

# Extract the tar to /root/original_tarred_names
print "\n Extracting tar as /root/mongodb.tar \n";
system("tar -xvf /root/downloads/mongodb.tar -C /root");

# This extracts with the original name mongodb-linux-x86 etc, so for ease of use find the new name and change it to mongodb

print "\n Searching for mongodb-linux- directory\n  ";

opendir( DIR, "/root" );
while ( my $mongodir = readdir DIR ) {
    next if ( $mongodir eq "." or $mongodir eq ".." );

    if ( -d $mongodir && $mongodir =~ m/^mongodb-linux-/ ) {
        rename( $mongodir, 'mongodb' );
        print " Renamed extracted mongodb-linux- to mongodb...\n";
    }

}

print "\n mongodb binaries are in /root/mongodb,\n now creating /data/db \n";

system("mkdir -p /data/db && chmod 755 /data/db ");

print
  "\n Creating a specific directory for the mongod logs: /var/log/mongod/ \n";
system("mkdir /var/log/mongod");

print "\n Now creating mongo config file: /root/mongodb/mongod.conf \n";
system(
"echo 'httpinterface=true' >> /root/mongodb/mongod.conf; echo 'rest=true' >> /root/mongodb/mongod.conf; echo 'fork=true' >> /root/mongodb/mongod.conf; echo 'logpath=/var/log/mongod/mongod.log' >> /root/mongodb/mongod.conf"
);

# run mongodb with the --config or -f option to load the specified conf file, e.g. mongod --config /root/mongodb/mongod.conf
# $PATH is shell variable, from perl you should use it as perl variable $ENV{PATH}

# Set the path for mongodb
print "\n Adding /root/mongodb/bin to the path \n";

# THIS MIGHT NOT WORK FROM WITHIN THE SCRIPT
system("export PATH=/root/mongodb/bin:\$PATH");

# Add this to bashrc for next time...
system("echo 'export PATH=/root/mongodb/bin:\$PATH' >> /root/.bashrc");

# Now for a finishing message

print << "MESSAGE";

     ** About to start mongodb **
 Will now run mongod -f /root/mongodb/mongod.conf
 This forks the mongod daemon with:
 httpinterface enabled on localhost:28017
 Logging to /var/log/mongod/mongod.log

 If the log file cannot be created, the mongod fork will not work.
 This will exit with a general error,
 ERROR: child process failed, exited with error number 1
 If there is a mongod process already running, there will be an error 100
 ERROR: child process failed, exited with error number 100
 Journal directory is created when run, journal dir=/data/db/journal

 To stop the mongo process: mongod --shutdown
 To CIFS connect from Windows to $user home folder,
 click Start & in the search bar:

 \\\\$ipaddress\\$user

 or paste this into Windows Exporer, 
 user name $user & password will be required.
 reset the samba share password wth with: smbpasswd -a $user

 You might want to remove components left by the installation 
 rm -r /root/downloads
MESSAGE

print "\n Starting mongod \n";
system("/root/mongodb/bin/mongod -f /root/mongodb/mongod.conf");

print "Waiting a few seconds for mongod to start before testing ... \n";
sleep 3;

print "\n Test local conection \n";
system("nc -zvv localhost 27017");

print "\n Check smbstatus \n";
system("smbstatus");

# CREATE WEB INDEX PAGE
# dont expect the link back into user directories to work without more work

# SUB TO CREATE INDEX
sub indexhtml {

my $index_html = << "INDEX";
<html><body><h1>Welcome to dbDotCad</h1>
<p>Created with  $PROGRAM_NAME V$VERSION </p>
<a href="/home/$user/send_for_review/">Sent for review folder test link</a>
<p>For samba share:  \\\\$ipaddress\\$user </p>
<p> href="smb://$ipaddress/$user/">Link to samba share</a><p>
</body></html>

INDEX


# open index.html for writing
if ( !open my $INDEX_HTML, '>', '/var/www/index.html' ) {
    print "\n  index.html would not open for reading \n";
}
else {
    print "\n Writing index.html - check it out at http://$ipaddress/\n";
 print $INDEX_HTML "$index_html";

    close $INDEX_HTML or carp "Unable to close /var/www/index.html";

}
}

indexhtml;

# CREATE OTHER SCRIPTS

print "\n Creating a startup shell script as /root/startup.sh \n";

if ( !open my $STARTUP, '>', '/root/startup.sh' ) {
    print "\n  /root/startup.sh would not open for writing\n";
}

# write $startup to start.sh file and make it executable
else {
    print $STARTUP "$startup";
    system("chmod 755 /root/startup.sh");
    close $STARTUP or carp "Unable to close /root/startup.sh";
}

print
" Using crontab -e for the root user, add \n \@reboot /root/startup.sh\n if required \n";

print
  "\n Creating javascript /root/mongodb/ddc_create.js to initialize database\n";

# SUB TO CREATE INITIALIZE JAVA SCRIPT

sub ddc_initialize {

# This script is used with the mongo command to create the ddc database
# printjson is required to see the output if calling script via 'mongo dbname script.js'
# usage, /pathto/mongo ddc /pathto/create_ddc.js
# dbname is specified after mongo command as defining this in the script e.g.
# db = getSiblingDB('ddc'); //use ddc// [must use single quotes around database name]
# does not work unless the database already exists
# db must contain an entry in order to display with show db, so insert dummy document(s) before show dbs
# my $ddc_create = 'some text string';

    my $ddc_create = << 'TAG';
    // create_ddc.js
    // -------//
    
    db.ddc_testblock.insert({"_id" : "'deleteme_id1", "author" : "floss1138", "language" : "javascript", "mission" : "Global domination"});
    db.ddc_testblock.insert({"_id" : "'deleteme_id2", "author" : "floss1139", "language" : "javascript", "mission" : "Global defence"});
    db.ddc_testblock.insert({"_id" : "'deleteme_id3", "author" : "floss1140", "language" : "javascript", "mission" : "Global destruction"});
    
    // now test to see if this worked
    printjson(db.adminCommand('listDatabases')); // show dbs
    printjson(db.getCollectionNames()); // show collections or tables
    
TAG

    # open ddc_create.js for writing
    if ( !open my $JS, '>', '/root/mongodb/ddc_create.js' ) {
        print "\n  ddc_create.js would not open for writing \n";
    }
    else {
        print "\n Writing ddc_create.js \n";
        print $JS "$ddc_create";

        close $JS or carp "Unable to close /root/mongodb/ddc_create.js\n";

    }
}

ddc_initialize;

print
"ddc_create.js ready to run, running '/root/mongodb/bin/mongo ddc /root/mongodb/ddc_create.js' to create the ddc database...\n";
print "... this hung last time I tried it after a <STDIN>\n";
system("/root/mongodb/bin/mongo ddc /root/mongodb/ddc_create.js");

print
"\n *** The End *** \n \n If capturing the script output, you may want to cancel that now ...\n and reload the shell to take advantage of the new path  source ~/.bashrc\n\n     Live long and prosper\n\n";

exit 0;

__END__

POINTS OF NOTE:
If the path is not working, start mongodb as:
/root/mongodb/bin/mongod --config /root/mongodb/mongod.conf
-f can be used instead of --config

Edit the crontab to run the script at boot time, using crontab -e for the root user:
@reboot /home/user/startup.sh
and check it with crontab -l 

Dont try and use 'system' for cd or path changes as it only changes the sub shell running the script and not the root shell,
perl has its own chdir commands for that.

Consider samba security:
usershare allow guests = yes # change to no
#   security = user # enable as we are using a user account

Apaceh2
Apache2 document root is defined in:
/etc/apache2/sites-available/default
The default created by the installation is:
/var/www/index.html

TODO 

ADD SUB TO CREATE AN INITIAL WEB PAGE

sub indexhtml {

my $index_html = << "INDEX";
<html><body><h1>Welcome to dbDotCad</h1>
<p>Created with  $PROGRAM_NAME V$VERSION </p>
<a href="/sent_for_review/">Sent for review folder test link</a>
<p>Link to samba share:  \\\\$ipaddress\\$user </p>
</body></html>

INDEX


# open index.html for writing
if ( !open my $INDEX_HTML, '>', '/var/www/index.html' ) {
    print "\n  index.html would not open for reading \n";
}
else {
    print "\n Writing index.html \n";
 print $INDEX_HTML "$index_html";
 
    close $INDEX_HTML or carp "Unable to close /var/www/index.html";

}
}

REMOVE MONGO ERROR

WARNING: /sys/kernel/mm/transparent_hugepage/defrag is 'always'

Official MongoDB documentation gives several solutions for this issue. You can also try this solution, which worked for me:

1.Open /etc/init/mongod.conf file.

2.Add the lines below immediately after chown $DEAMONUSER /var/run/mongodb.pid and before end script.

3.Restart mongod (service mongod restart).
Here are the lines to add to /etc/init/mongod.conf:

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

SCRIPT ERRORS


