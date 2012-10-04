// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-dynamodb.js - integration tests for Amazon DynamoDB
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
var DynamoDB = awssum.load('amazon/dynamodb').DynamoDB;
var inspect = require('eyes').inspector();

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var dynamodb;
try {
    dynamodb = new DynamoDB({
        'accessKeyId'     : env.ACCESS_KEY_ID,
        'secretAccessKey' : env.SECRET_ACCESS_KEY,
        'awsAccountId'    : env.AWS_ACCOUNT_ID,
        'region'          : amazon.US_EAST_1
    });
}
catch(e) {
    // env vars aren't set, so skip these integration tests
    process.exit();
}

// --------------------------------------------------------------------------------------------------------------------
// Amazon:DynamoDB operations

// just check one request, checks the signature to be honest
test('DynamoDB:ListTables - (1) Standard', function(t) {
    var opts = {};
    dynamodb.ListTables(function(err, data) {
        t.notOk(err, 'DynamoDB:ListTables - (1) Standard : no error');
        t.equal(data.StatusCode, 200, 'StatusCode is 200');
        t.equal(data.Headers['content-type'], 'application/x-amz-json-1.0', 'ContentType is json v1.0 (not v1.1)');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
