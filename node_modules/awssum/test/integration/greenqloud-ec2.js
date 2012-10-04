// --------------------------------------------------------------------------------------------------------------------
//
// integration/greenqloud-ec2.js - integration tests for GreenQloud EC2
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
var greenqloud = awssum.load('greenqloud/greenqloud');
var Ec2 = awssum.load('greenqloud/ec2').Ec2;
var inspect = require('eyes').inspector();

// --------------------------------------------------------------------------------------------------------------------

var env = process.env;
var ec2;
try {
    ec2 = new Ec2({
        'accessKeyId'     : env.GREENQLOUD_ACCESS_KEY_ID,
        'secretAccessKey' : env.GREENQLOUD_SECRET_ACCESS_KEY,
        'region'          : greenqloud.IS_1,
    });
}
catch(e) {
    // env vars aren't set, so skip these integration tests
    process.exit();
}

// --------------------------------------------------------------------------------------------------------------------
// GreenQloud:Ec2 operations

// this test just checks that the initial parameter checking passed
test('Ec2:CreateTags - (1) Standard', function(t) {
    var opts = {
        ResourceId : 'i-cafebabe',
        Tag : {
            Key : 'stack', Value : 'production',
        },
    };
    ec2.CreateTags(opts, function(err, data) {
        t.equal(
            err.Body.Response.Errors.Error.Code,
            'MissingParameter', // InvalidInstanceID.NotFound ???
            'Ec2:CreateTags - (1) Standard : got an error (invalid instance)'
        );
        t.notOk(data, 'Ec2:CreateTags - (1) Standard : data not given');
        t.end();
    });
});

// this test just checks that the initial parameter checking passed
test('Ec2:CreateTags - (2) Standard', function(t) {
    var opts = {
        ResourceId : [ 'i-cafebabe' ],
        Tag : {
            Key : 'stack', Value : 'production',
        },
    };
    ec2.CreateTags(opts, function(err, data) {
        t.equal(
            err.Body.Response.Errors.Error.Code,
            'MissingParameter', // InvalidInstanceID.NotFound ???
            'Ec2:CreateTags - (2) Standard : got an error (invalid instance)'
        );
        t.notOk(data, 'Ec2:CreateTags - (2) Standard : data not given');
        t.end();
    });
});

// this test just checks that the initial parameter checking passed
test('Ec2:CreateTags - (3) Standard', function(t) {
    var opts = {
        ResourceId : [ 'i-cafebabe', 'i-deadbeef' ],
        Tag : [
            { Key : 'stack', Value : 'testing', },
            { Key : 'stack', Value : 'staging', },
        ],
    };
    ec2.CreateTags(opts, function(err, data) {
        t.equal(
            err.Body.Response.Errors.Error.Code,
            'InvalidParameterValue', // InvalidInstanceID.NotFound ???
            'Ec2:CreateTags - (3) Standard : got an error (invalid instance)'
        );
        t.notOk(data, 'Ec2:CreateTags - (3) Standard : data not given');
        t.end();
    });
});

// --------------------------------------------------------------------------------------------------------------------
