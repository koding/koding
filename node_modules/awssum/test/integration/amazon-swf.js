// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-swf.js - integration tests for Amazon SWF
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
var Swf = awssum.load('amazon/swf').Swf;

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var swf;
try {
    swf = new Swf({
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
// Amazon:SWF operations

var args = {
    RegistrationStatus : 'REGISTERED',
};

test('Swf:ListDomains - Standard', function(t) {
    swf.ListDomains(args, function(err, data) {
        t.equal(err, null, 'SWF:ListDomains - Standard : Error should be null');
        t.ok(data, 'SWF:ListDomains - Standard : data ok');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
