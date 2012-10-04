// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-s3.js - integration tests for Amazon S3
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------
// requires

var fs = require('fs');
var test = require('tap').test;
var awssum = require('../../');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var s3;
try {
    s3 = new S3({
        'accessKeyId'     : env.ACCESS_KEY_ID,
        'secretAccessKey' : env.SECRET_ACCESS_KEY,
        'region'          : amazon.US_EAST_1
    });
}
catch(e) {
    // env vars aren't set, so skip these integration tests
    process.exit();
}

// --------------------------------------------------------------------------------------------------------------------
// Amazon:S3 operations

var bucket = 'pie-18';

test('S3:Multi Part Uploads', function(t) {
    var initiateOpts = {
        BucketName : bucket,
        ObjectName : 'multipart.txt',
    };

    s3.InitiateMultipartUpload(initiateOpts, function(err, data) {
        t.equal(err, null, 'S3:InitiateMultipartUpload - using a Range : Error should be null');
        t.ok(data.Body.InitiateMultipartUploadResult.UploadId, 'S3:InitiateMultipartUpload - got an UploadId');

        var uploadId = data.Body.InitiateMultipartUploadResult.UploadId;
        var content = 'Hello, World!';
        var uploadPartOpts = {
            BucketName    : bucket,
            ObjectName    : 'multipart.txt',
            PartNumber    : 1,
            UploadId      : uploadId,
            ContentLength : content.length,
            Body          : content,
        };

        s3.UploadPart(uploadPartOpts, function(err, data) {
            t.equal(err, null, 'S3:UploadPart : err should be null');
            t.equal(data.Headers.etag.length, 32+2, 'S3:UploadPart : data.etag should be 34 chars long');
            t.ok(data.Headers['x-amz-request-id'], 'S3:UploadPart : request should have an id');
            t.ok(data.Headers['x-amz-id-2'], 'S3:UploadPart : request should have a 2nd id');

            var completeOptions = {
                BucketName    : bucket,
                ObjectName    : 'multipart.txt',
                UploadId      : uploadId,
                Parts         : [
                    {
                        PartNumber : 1,
                        ETag       : data.Headers.etag,
                    }
                ],
            };

            s3.CompleteMultipartUpload(completeOptions, function(err, data) {
                t.equal(err, null, 'S3:UploadPart : err should be null');
                console.log(data);
                t.end();
            });
        });

    });
});

// --------------------------------------------------------------------------------------------------------------------
