// --------------------------------------------------------------------------------------------------------------------
//
// s3.js - test for AWS Simple Notification Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
// requires

var tap = require("tap"),
    test = tap.test,
    plan = tap.plan,
    _ = require('underscore');
var awssum = require('../');
var amazon;
var S3;

// --------------------------------------------------------------------------------------------------------------------
// basic tests

test("load s3", function (t) {
    amazon = awssum.load('amazon/amazon');
    t.ok(amazon, 'object loaded');

    S3 = awssum.load('amazon/s3').S3;
    t.ok(S3, 'object loaded');

    t.end();
});

test("create s3 object", function (t) {
    var s3 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    t.equal('access_key_id', s3.accessKeyId(), 'Access Key ID set properly');
    t.equal('secret_access_key', s3.secretAccessKey(), 'Secret Access Key set properly');
    t.equal('aws_account_id', s3.awsAccountId(), 'AWS Account ID set properly');
    t.equal('us-west-1', s3.region(), 'Region is set properly');

    t.end();
});

test("test all endpoints", function (t) {
    var s31 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_EAST_1
    });
    var s32 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });
    var s33 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.EU_WEST_1
    });
    var s34 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.AP_SOUTHEAST_1
    });
    var s35 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.AP_NORTHEAST_1
    });

    t.equal('s3.amazonaws.com', s31.host(), '1) Endpoint is correct');
    t.equal('s3-us-west-1.amazonaws.com', s32.host(), '2) Endpoint is correct');
    t.equal('s3-eu-west-1.amazonaws.com', s33.host(), '3) Endpoint is correct');
    t.equal('s3-ap-southeast-1.amazonaws.com', s34.host(), '4) Endpoint is correct');
    t.equal('s3-ap-northeast-1.amazonaws.com', s35.host(), '5) Endpoint is correct');

    t.end();
});

test("test strToSign", function (t) {
    var s3 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    // NOTE: since strToSign() is really a private method, we have to set up the options to be pretty complete
    // (including empty headers and params) since in the class they would have been setup before this method is every
    // called.

    var strToSignEmpty1 = s3.strToSign(
        {
            method : 'GET',
            path : '/',
            params : [],
            headers : {},
        },
        {}
    );
    t.equal(strToSignEmpty1, "GET\n\n\n\n/", 'strToSign of ListBuckets');

    // set up some generic headers first
    var headers = {};
    headers.Date = "Mon, 26 Oct 2011 16:07:36 Z";

    // test an initial string
    var strToSign = s3.strToSign(
        {
            method : 'POST',
            path : '/',
            params : [ { name : 'BucketName', value : 'bulk' } ],
            headers : headers,
        },
        { BucketName : 'bulk' }
    );
    t.equal(strToSign, "POST\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/", 'strToSign of common params');

    // do a subresource test
    var strToSign2 = s3.strToSign(
        {
            method : 'POST',
            path : '/',
            params : [ { name : 'versioning' }, { name : 'BucketName', value : 'bulk' } ],
            headers : headers,
        },
        { BucketName : 'bulk' }
    );

    t.equal(
        strToSign2,
        "POST\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/?versioning",
        'strToSign with subresource of versioning'
    );

    // do a subresource test
    var strToSign3 = s3.strToSign(
        {
            method : 'POST',
            path : '/',
            params : [ { name : 'website' }, { name : 'BucketName', value : 'bulk' } ],
            headers : headers,
        },
        { BucketName : 'bulk' }
    );
    t.equal(
        strToSign3,
        "POST\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/?website",
        'strToSign with subresource of website'
    );

    // do an object test
    var strToSign4 = s3.strToSign(
        {
            method : 'PUT',
            path : '/',
            params : [ { name : 'BucketName', value : 'bulk' }, { name : 'ObjectName', value : 'my-object.txt' } ],
            headers : headers,
        },
        { BucketName : 'bulk', ObjectName : 'my-object.txt' }
    );
    t.equal(
        strToSign4,
        "PUT\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/my-object.txt",
        'strToSign with an object'
    );


    // do an object with a space in the name
    var strToSign5 = s3.strToSign(
        {
            method : 'PUT',
            path : '/',
            params : [ { name : 'BucketName', value : 'bulk' }, { name : 'ObjectName', value : 'my object.txt' } ],
            headers : headers,
        },
        { BucketName : 'bulk', ObjectName : 'my object.txt' }
    );
    t.equal(
        strToSign5,
        "PUT\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/my%20object.txt",
        'strToSign with an object'
    );

    // do an object with 'x-amz-*' headers
    headers['x-amz-meta-username'] = "chilts";
    var strToSign6 = s3.strToSign(
        {
            method : 'PUT',
            path : '/',
            params : [ { name : 'BucketName', value : 'bulk' }, { name : 'ObjectName', value : 'my-object.txt' } ],
            headers : headers,
        },
        { BucketName : 'bulk', ObjectName : 'my-object.txt' }
    );
    t.equal(
        strToSign6,
        "PUT\n\n\nMon, 26 Oct 2011 16:07:36 Z\nx-amz-meta-username:chilts\n/bulk/my-object.txt",
        'strToSign with an object'
    );

    t.end();
});

test("test signature", function (t) {
    var s3 = new S3({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    var strToSign = "GET\n\n\nTue, 25 Oct 2011 03:09:21 UTC\n/";
    var sig = s3.signature(strToSign);
    t.equal(sig, 'OFs3nLlSvlN6EaeNy/IluZpS+E8=', 'signature of ListBuckets request');

    var strToSign2 = "GET\n\n\nTue, 25 Oct 2011 03:09:21 UTC\n/bulk/?versioning";
    var sig2 = s3.signature(strToSign2);
    t.equal(sig2, 'zxmJifiGCl8WgMu2XLaiEx0o5Wo=', 'signature of ListBuckets request with versioning');

    var strToSign3 = "PUT\n\n\nMon, 26 Oct 2011 16:07:36 Z\n/bulk/my-object.txt";
    var sig3 = s3.signature(strToSign3);
    t.equal(sig3, 'jngqlGWTmPDVu3BO7tcYSQHNglc=', 'signature of PutObject');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
