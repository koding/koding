// --------------------------------------------------------------------------------------------------------------------
//
// integration/greenqloud-s3.js - integration tests for GreenQloud S3
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
var greenqloud = awssum.load('greenqloud/greenqloud');
var S3 = awssum.load('greenqloud/s3').S3;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var s3;
try {
    s3 = new S3({
        'accessKeyId'     : env.GREENQLOUD_ACCESS_KEY_ID,
        'secretAccessKey' : env.GREENQLOUD_SECRET_ACCESS_KEY,
        'region'          : greenqloud.IS_1,
    });
}
catch(e) {
    // env vars aren't set, so skip these integration tests
    process.exit();
}

// --------------------------------------------------------------------------------------------------------------------
// Greenqloud:S3 operations

var bucket = 'pie-18';

test('S3:ListBuckets - Standard', function(t) {
    s3.ListBuckets(function(err, data) {
        t.equal(err, null, 'S3:ListBuckets - Standard : Error should be null');
        t.ok(data, 'S3:ListBuckets - Standard : data ok');
        t.end();
    });
});

test('S3:ListObjects - Standard', function(t) {
    var args = {
        BucketName : bucket,
    };

    s3.ListObjects(args, function(err, data) {
        t.equal(err, null, 'S3:ListObjects - Standard : Error should be null');
        t.ok(data, 'S3:ListObjects - Standard : data ok');
        t.end();
    });
});

test('S3:ListObjects - MaxKeys and Prefix', function(t) {
    var args = {
        BucketName : bucket,
        MaxKeys    : 10,
        Prefix     : 'm',
    };

    s3.ListObjects(args, function(err, data) {
        t.equal(err, null, 'S3:ListObjects(MaxKeys/Prefix) : Error should be null');
        t.ok(data, 'S3:ListObjects - MaxKeys and Prefix : data ok');
        // t.ok(data.Headers['x-amz-request-id'], 'S3:ListObjects(MaxKeys/Prefix) : Request should have an id');
        // t.ok(data.Headers['x-amz-id-2'], 'S3:ListObjects(MaxKeys/Prefix) : request should have a 2nd id');
        t.ok(data.Body.ListBucketResult.Contents.length > 0, 'S3:ListObjects(MaxKeys/Prefix) : should have more than 1 item');
        t.end();
    });
});

test('S3:GetObject - without ResponseContentType', function(t) {
    var opts = {
        BucketName          : bucket,
        ObjectName          : 'test-object-with-metadata.txt',
    };

    s3.GetObject(opts, function(err, data) {
        t.equal(err, null, 'S3:GetObject - without ResponseContentType : Error should be null');
        t.ok(data, 'S3:GetObject - without ResponseContentType : data ok');
        t.equal(data.Headers['content-type'], 'application/octet-stream', 'S3:GetObject - without ResponseContentType : header correct');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
