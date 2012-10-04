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
        t.ok(data.Headers['x-amz-request-id'], 'S3:ListObjects(MaxKeys/Prefix) : Request should have an id');
        t.ok(data.Headers['x-amz-id-2'], 'S3:ListObjects(MaxKeys/Prefix) : request should have a 2nd id');
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
        t.equal(data.Headers['content-type'], 'binary/octet-stream', 'S3:GetObject - without ResponseContentType : header correct');
        t.end();
    });
});

test('S3:GetObject - with ResponseContentType', function(t) {
    var optionsWithResponseContentType = {
        BucketName          : bucket,
        ObjectName          : 'test-object-with-metadata.txt',
        ResponseContentType : 'text/plain',
    };

    s3.GetObject(optionsWithResponseContentType, function(err, data) {
        t.equal(err, null, 'S3:GetObject - with ResponseContentType : Error should be null');
        t.ok(data, 'S3:GetObject - with ResponseContentType : data ok');
        t.equal(data.Headers['content-type'], 'text/plain', 'S3:GetObject - with ResponseContentType : header correct');
        t.end();
    });
});

test('S3:PutObject - Standard', function(t) {
    var body = "Hello, World!\n";

    var args = {
        BucketName    : bucket,
        ObjectName    : 'test-object.txt',
        ContentLength : Buffer.byteLength(body),
        Body          : body,
    };

    s3.PutObject(args, function(err, data) {
        t.equal(err, null, 'S3:PutObject - Standard : Error should be null');
        t.ok(data, 'S3:PutObject - Standard : data ok');
        t.end();
    });
});

test('S3:PutObject - Stream', function(t) {
    // you must run fs.stat to get the file size for the content-length header (s3 requires this)
    fs.stat(__filename, function(err, file_info) {
        t.equal(err, null, 'S3:PutObject - stat should have worked');

        var bodyStream = fs.createReadStream( __filename );

        t.ok( file_info.size > 0, 'S3:PutObject - Stream : Filesize should be greater than 0');

        var options = {
            BucketName    : bucket,
            ObjectName    : 'amazon.js',
            ContentLength : file_info.size,
            Body          : bodyStream
        };

        s3.PutObject(options, function(err, data) {
            t.equal(err, null, 'S3:PutObject - Stream : Error should be null');
            t.ok(data, 'S3:PutObject - Stream : data ok');
            t.end();
        });
    });
});

test('S3:CopyObject - Simple', function(t) {
    var options = {
        BucketName : bucket,
        ObjectName : 'copy-of-test-object.txt',
        SourceBucket : bucket,
        SourceObject : 'test-object.txt',
    };

    s3.CopyObject(options, function(err, data) {
        t.equal(err, null, 'S3:CopyObject - Simple : Error should be null');
        t.ok(data, 'S3:CopyObject - Simple : data ok');
        t.end();
    });
});

test('S3:GetObject - With a Range Header', function(t) {
    var opts = {
        BucketName          : bucket,
        ObjectName          : 'test-object.txt',
        ResponseContentType : 'text/plain',
        Range               : 'bytes=3-8',
    };

    s3.GetObject(opts, function(err, data) {
        t.equal(err, null, 'S3:GetObject - using a Range : Error should be null');
        t.equal(data.Body.toString('utf8'), 'lo, Wo', 'S3:GetObject - using a Range : data ok');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
