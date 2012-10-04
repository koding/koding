// --------------------------------------------------------------------------------------------------------------------
//
// app.js - Example to show single and multiple file uploads and different ways you can set s3ObjectName.
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var express = require('express');
var connectStreamS3 = require('../connect-stream-s3');
var amazon = require('awssum').load('amazon/amazon');

// ----------------------------------------------------------------------------

// set up some middleware that we'll specifically use for certain paths
var s3StreamMiddleware = connectStreamS3({
    accessKeyId     : process.env.ACCESS_KEY_ID,
    secretAccessKey : process.env.SECRET_ACCESS_KEY,
    awsAccountId    : process.env.AWS_ACCOUNT_ID,
    region          : amazon.US_EAST_1,
    bucketName      : process.env.BUCKET_NAME,
    concurrency     : 2,
});

// middleware to set the name of the single file upload to contain the date and time
var setS3ObjectName = function(req, res, next) {
    // firstly, check that the 'file' exists
    if ( req.files.file ) {
        //
        // Note:
        //
        // This is an example of where you may use the filename provided by the user. If for example they upload a file
        // which is named 'cat.png', then req.files.file.name will contain 'cat.png'. So that we don't overwrite an
        // existing file that they may have uploaded, we rename it to contain the date to seconds accuracy.
        //
        // This approach is pretty bad and there are better ways but it is here to document what you can do so that
        // connect-stream-s3 doesn't keep overwriting the same object in your bucket.
        //
        req.files.file.s3ObjectName = (new Date()).toISOString().substr(0, 19) + '-' + req.files.file.name;
    }
    // Else: no file, just ignore this for now. You may want to have checked that a file exists in some validation
    // middleware called prior to this one.

    // next middleware
    next();
};

var randomiseS3ObjectNames = function(req, res, next) {
    // Each file will be uploaded in the format 'username/xxxxxxxxx.ext' where:
    //
    // * username = their unique username you presumably get from their session
    // * xxxxxxxxx = a random set for digits (you could use letters too, but digits for ease of use here)
    // * ext = the original filename extension (if it exists)
    //
    // Note: whilst the chances of ObjectNames clashing with existing objects in your bucket are there, it is possible.
    // You may want to do something so that your ObjectNames are a primary key (stored somewhere) so that you can
    // easily check for existance.

    var m;
    var objectName;

    // loop through all of the uploaded files and assign a random name to them
    for(var key in req.files) {
        // basepath
        objectName = req.files[key].s3ObjectName = 'username/' + parseInt(Math.random() * 1000000000);

        // check for an extension
        m = req.files[key].name.match(/\.(\w+)$/);
        if ( m ) {
            objectName += '.' + m[1];
        }

        // set the s3ObjectName to this created objectName
        req.files[key].s3ObjectName = objectName;
    }
    next();
}

// ----------------------------------------------------------------------------

// create your express server
var app = module.exports = express.createServer();

// set up the views
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');

// add the static middleware
app.use(express.static(__dirname + '/htdocs/'));

// bodyParser :)
app.use(express.bodyParser());

// ----------------------------------------------------------------------------
// pages

// serve a main page
app.get('/', function(req, res, next) {
    res.render('index', { title: 'Upload a single file (using Express BodyParser())' })
});

app.post('/single-file', setS3ObjectName, s3StreamMiddleware, function(req, res, next) {
    console.log('Single file uploaded as : ' + req.files.file.s3ObjectName);
    res.redirect('/thanks');
});

app.post('/multiple-files', randomiseS3ObjectNames, s3StreamMiddleware, function(req, res, next) {
    for(var key in req.files) {
        console.log('File "' + key + '" uploaded as : ' + req.files[key].s3ObjectName);
    }
    res.redirect('/thanks');
});

app.post('/upload', s3StreamMiddleware, function(req, res, next) {
    console.log('We should never get here, since connect-stream-s3 will error out');
    res.redirect('/thanks');
});

app.get('/thanks', function(req, res, next) {
    res.render('thanks', { title: 'Thanks' })
});

// ----------------------------------------------------------------------------

// listen
app.listen(3000);

console.log("Express server listening on port %d in %s mode.", app.address().port, app.settings.env);

// ----------------------------------------------------------------------------
