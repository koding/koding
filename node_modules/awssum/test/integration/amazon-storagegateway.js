// --------------------------------------------------------------------------------------------------------------------
//
// integration/amazon-storagegateway.js - integration tests for Amazon Storage Gateway
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
var StorageGateway = awssum.load('amazon/storagegateway').StorageGateway;
var inspect = require('eyes').inspector();

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var sg;
try {
    sg = new StorageGateway({
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
// Amazon:StorageGateway operations

// just check one request, checks the signature to be honest
test('StorageGateway:ListGateways - (1) Standard', function(t) {
    var opts = {};
    sg.ListGateways(function(err, data) {
        t.notOk(err, 'StorageGateway:ListGateways - standard : no error');
        t.ok(data, 'StorageGateway:ListGateways - standard : result ok');
        t.end();
    });
});

// check that the JSON is being created correctly
test('StorageGateway:ListGateways - (2) with limit', function(t) {
    var opts = {};
    sg.ListGateways({ Limit : 5 }, function(err, data) {
        t.notOk(err, 'StorageGateway:ListGateways - (2) with limit : no error');
        t.ok(data, 'StorageGateway:ListGateways - (2) with limit : result ok');
        t.end();
    });
});

// check that the JSON is being created correctly
test('StorageGateway:ListVolumes', function(t) {
    var opts = {};
    sg.ListVolumes({ GatewayARN : 'invalid-arn' }, function(err, data) {
        t.ok(err, 'StorageGateway:ListVolumes : error');
        t.equal(
            err.Body.__type,
            'ValidationException',
            'StorageGateway:ListVolumes : error type should be ValidationException'
        );
        t.notOk(data, 'StorageGateway:ListVolumes : no result');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
