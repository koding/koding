// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-emr.js - integration tests for Amazon EMR
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
var Emr = awssum.load('amazon/emr').Emr;
var inspect = require('eyes').inspector();

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var emr;
try {
    emr = new Emr({
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
// Amazon:Emr operations

// this test just checks that the initial parameter checking passed
test('Emr:DescribeJobFlows - (1) Standard', function(t) {
    var opts = {};
    emr.DescribeJobFlows(opts, function(err, data) {
        t.notOk(err, 'Emr:DescribeJobFlows - standard : no error');
        t.ok(data, 'Emr:DescribeJobFlows - standard : result ok');
        t.end();
    });
});

// this test just checks that the initial parameter checking passed
test('Emr:DescribeJobFlows - with states', function(t) {
    var opts = {
        JobFlowStates  : [ 'RUNNING', 'STARTING' ],
    };
    emr.DescribeJobFlows(opts, function(err, data) {
        t.notOk(err, 'Emr:DescribeJobFlows - with states : no error');
        t.ok(data, 'Emr:DescribeJobFlows - with states : result ok');
        t.end();
    });
});

// this test just checks that the initial parameter checking passed
test('Emr:DescribeJobFlows - invalid state', function(t) {
    var opts = {
        JobFlowStates  : [ 'RUNNING', 'PENDING' ],
    };
    emr.DescribeJobFlows(opts, function(err, data) {
        t.equal(
            err.Body.ErrorResponse.Error.Code,
            'ValidationError',
            'Emr:DescribeJobFlows - Standard : got an error (invalid state)'
        );
        t.notOk(data, 'Emr:DescribeJobFlows - Standard : data not given');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
