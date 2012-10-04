// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-iam.js - integration tests for Amazon IAM
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
var Iam = awssum.load('amazon/iam').Iam;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var iam;
try {
    iam = new Iam({
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
// Amazon:IAM operations

test('Iam:GetUser - Standard', function(t) {
    iam.GetUser(function(err, data) {
        t.equal(err, null, 'IAM:GetUser - Standard : Error should be null');
        t.ok(data, 'IAM:GetUser - Standard : data ok');
        t.equal(data.StatusCode, 200, 'IAM:GetUser - Standard : 200');
        t.end();
    });
});

test('Iam:ListAccessKeys - Standard', function(t) {
    iam.ListAccessKeys(function(err, data) {
        t.equal(err, null, 'IAM:ListAccessKeys - Standard : Error should be null');
        t.ok(data, 'IAM:ListAccessKeys - Standard : data ok');
        t.equal(
            data.Body.ListAccessKeysResponse.ListAccessKeysResult.IsTruncated,
            'false',
            'IAM:ListAccessKeys - Standard : truncated is false'
        );
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
