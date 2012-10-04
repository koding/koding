// --------------------------------------------------------------------------------------------------------------------
//
// connect-stream-s3.js - Middleware to stream a file to Amazon S3
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var fs = require('fs');

var async = require('async');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

module.exports = function(options) {
    options = options || {};

    // remember these (by taking local variables)
    var accessKeyId     = options.accessKeyId;
    var secretAccessKey = options.secretAccessKey;
    var awsAccountId    = options.awsAccountId;
    var region          = options.region;
    var bucketName      = options.bucketName;
    var concurrency     = options.concurrency || 3;

    // create the S3 API
    var s3 = new S3({
        'accessKeyId'     : accessKeyId,
        'secretAccessKey' : secretAccessKey,
        'awsAccountId'    : awsAccountId,
        'region'          : region
    });

    return function handler(req, res, next) {
        // check that each uploaded file has a s3ObjectName property (and quit early)
        for(var fieldname in req.files) {
            if ( !req.files[fieldname].s3ObjectName ) {
                next('Error: The s3ObjectName field has not been set on the uploaded file "' + fieldname + '".');
                return;
            }
        }

        // remember what happened to each of these files
        var allOk = true;

        // create an async function to upload the file
        var upload = function(fieldname, callback) {
            // open the file as a read stream
            var bodyStream = fs.createReadStream( req.files[fieldname].path );

            // create the data for s3.PutObject()
            var data = {
                'BucketName'    : bucketName,
                'ObjectName'    : req.files[fieldname].s3ObjectName,
                'ContentLength' : req.files[fieldname].size,
                'Body'          : bodyStream,
            };

            s3.PutObject(data, function(err, data) {
                // remember what happened
                req.files[fieldname].s3 = {
                    'err'  : err,
                    'data' : data,
                };
                if (err) {
                    allOk = false;
                } // else, everything was ok

                // tell the queue we're finished with this file
                callback();
            });
        }

        // create a queue so we can do all of the uploaded files to S3
        var q = async.queue(upload, concurrency);

        // now, add all of these fields onto the queue
        for(var fieldname in req.files) {
            q.push(fieldname);
        }

        // once the queue is completely empty, call the next middleware
        q.drain = function() {
            if ( allOk ) {
                next();
            }
            else {
                next('One or more of the files failed to upload to S3.');
            }
        };
    };
};

// --------------------------------------------------------------------------------------------------------------------
