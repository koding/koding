// --------------------------------------------------------------------------------------------------------------------
//
// integration/agent.js - integration tests for agent, using Amazon S3
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------
// requires

var https = require('https');
var fs = require('fs');

var test = require('tap').test;
var awssum = require('../../');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var noAgent, withAgent, falseAgent;
try {
    noAgent = new S3({
        'accessKeyId'     : env.ACCESS_KEY_ID,
        'secretAccessKey' : env.SECRET_ACCESS_KEY,
        'region'          : amazon.US_EAST_1,
    });
    withAgent = new S3({
        'accessKeyId'     : env.ACCESS_KEY_ID,
        'secretAccessKey' : env.SECRET_ACCESS_KEY,
        'region'          : amazon.US_EAST_1,
        'agent'           : new https.Agent({ maxSockets: 1 }),
    });
    falseAgent = new S3({
        'accessKeyId'     : env.ACCESS_KEY_ID,
        'secretAccessKey' : env.SECRET_ACCESS_KEY,
        'region'          : amazon.US_EAST_1,
        'agent'           : false,
    });
}
catch(e) {
    // env vars aren't set, so skip these integration tests
    process.exit();
}

// --------------------------------------------------------------------------------------------------------------------
// Amazon:S3 operations

var bucket = 'pie-18';
var clients = {
    'noAgent'    : noAgent,
    'withAgent'  : withAgent,
    'falseAgent' : falseAgent
};

Object.keys(clients).forEach(function(name, i) {
    var client = clients[name];

    test('S3:ListBuckets - ' + name, function(t) {
        client.ListBuckets(function(err, data) {
            t.equal(err, null, 'S3:ListBuckets - ' + name + ' : Error should be null');
            t.ok(data, 'S3:ListBuckets - ' + name + ' : data ok');
            t.end();
        });
    });
});

// --------------------------------------------------------------------------------------------------------------------
