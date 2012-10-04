// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-cloudsearch.js - integration tests for Amazon CloudSearch
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
var CloudSearch = awssum.load('amazon/cloudsearch').CloudSearch;
var inspect = require('eyes').inspector();

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var cs;
try {
    cs = new CloudSearch({
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
// Amazon:CloudSearch operations

// just check one request, checks the signature to be honest
test('Cloudsearch: DescribeDomains - (1) Standard', function(t) {
    var opts = {};
    cs.DescribeDomains(function(err, data) {
        t.notOk(err, 'CloudSearch:DescribeDomains - standard : no error');
        t.ok(data, 'CloudSearch:DescribeDomains - standard : result ok');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
