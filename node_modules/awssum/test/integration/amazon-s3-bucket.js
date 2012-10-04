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

test('S3:GetBucketTagging - Standard', function(t) {
    s3.GetBucketTagging({ BucketName : 'pie-17' }, function(err, data) {
        t.ok(err, 'S3:GetBucketTagging - NoSuchTagSet');
        t.notOk(data, 'S3:GetBucketTagging - no data');

        t.equal(err.Body.Error.Code, 'NoSuchTagSet', 'S3:GetBucketTagging - checking error code');

        t.end();
    });
});

test('S3:PutBucketAcl - InvalidArgument', function(t) {
    var params = {
        BucketName         : 'pie-18',
        AccessControlPolicy  : {
            Owner : {
                ID : 'sdfgd',
                DisplayName : 'something',
            },
            AccessControlList : [
                {
                    Grant : {
                        Grantee : {
                            _attr :  {
                                'xmlns:xsi' : 'http://www.w3.org/2001/XMLSchema-instance',
                                'xsi:type' : 'CanonicalUser',
                            },
                            ID : '1111-2222-3333',
                            DisplayName : 'a name'
                        },
                        Permission : 'READ',
                    },
                },
            ]
        },
    };

    s3.PutBucketAcl(params, function(err, data) {
        t.ok(err, 'S3:PutBucketAcl - InvalidArgument');
        t.notOk(data, 'S3:PutBucketAcl - InvalidArgument');
        t.equal(err.StatusCode, 400, 'S3:PutBucketAcl - checking status code');
        t.equal(err.Body.Error.Code, 'InvalidArgument', 'S3:PutBucketAcl - checking error code');
        t.equal(err.Body.Error.ArgumentName, 'CanonicalUser/ID', 'S3:PutBucketAcl - checking argument name');
        t.equal(err.Body.Error.ArgumentValue, '1111-2222-3333', 'S3:PutBucketAcl - checking argument value');

        t.end();
    });
});

test('S3:PutBucketAcl - InvalidArgument', function(t) {
    var params = {
        BucketName : 'pie-18',
        // similar thing for all the other Grant* params
        GrantFullControl  : 'emailAddress="andychilton@gmail.com"',
    };

    s3.PutBucketAcl(params, function(err, data) {
        t.notOk(err, 'S3:PutBucketAcl - no error');
        t.ok(data, 'S3:PutBucketAcl - ok');

        t.equal(data.StatusCode, 200, 'S3:PutBucketAcl - checking status code');
        t.equal(data.Body, '', 'S3:PutBucketAcl - empty body');

        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
