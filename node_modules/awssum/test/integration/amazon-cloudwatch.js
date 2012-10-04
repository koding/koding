// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-cloudwatch.js - integration tests for Amazon CloudWatch
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
var CloudWatch = awssum.load('amazon/cloudwatch').CloudWatch;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var cw;
try {
    cw = new CloudWatch({
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
// Amazon:CloudWatch operations

test('CloudWatch:ListMetrics - Standard', function(t) {
    cw.ListMetrics(function(err, data) {
        t.equal(err, null, 'CloudWatch:ListMetrics - Standard : Error should be null');
        t.ok(data, 'CloudWatch:ListMetrics - Standard : data ok');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
