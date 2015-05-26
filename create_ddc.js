// create_ddc.js 
// -------//
// This script is used with the mongo command to create the ddc database
// printjson is required to see the output if calling script via 'mongo dbname script.js'
// usage, /pathto/mongo ddc /pathto/create_ddc.js
// dbname is specified after mongo command as defining this in the script e.g.
// db = getSiblingDB('ddc'); //use ddc// [must use single quotes around database name]
// does not work unless the database already exists
// db must contain an entry in order to display with show db, so insert dummy document(s) before show dbs

db.ddc_testblock.insert({"_id" : "'deleteme_id1", "author" : "floss1138", "language" : "javascript", "mission" : "Global domination"});
db.ddc_testblock.insert({"_id" : "'deleteme_id2", "author" : "floss1139", "language" : "javascript", "mission" : "Global defence"});
db.ddc_testblock.insert({"_id" : "'deleteme_id3", "author" : "floss1140", "language" : "javascript", "mission" : "Global destruction"});

// now test to see if this worked
printjson(db.adminCommand('listDatabases')); // show dbs
printjson(db.getCollectionNames()); // show collections or tables

