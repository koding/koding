// --------------------------------------------------------------------------------------------------------------------
//
// simpledb.js - test for AWS SimpleDB
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
var SimpleDB;
var esc = require('../lib/esc.js');

// --------------------------------------------------------------------------------------------------------------------
// basic tests

test("load simpledb", function (t) {
    amazon = awssum.load('amazon/amazon');
    t.ok(amazon, 'object loaded');

    SimpleDB = awssum.load('amazon/simpledb').SimpleDB;
    t.ok(SimpleDB, 'object loaded');

    t.end();
});

test("create simpledb object", function (t) {
    var sdb = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.US_WEST_1
    });

    t.equal('access_key_id', sdb.accessKeyId(), 'Access Key ID set properly');
    t.equal('secret_access_key', sdb.secretAccessKey(), 'Secret Access Key set properly');
    t.equal('aws_account_id', sdb.awsAccountId(), 'AWS Account ID set properly');
    t.equal('us-west-1', sdb.region(), 'Region is set properly');

    t.end();
});

test("test all endpoints", function (t) {
    var sdb1 = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.US_EAST_1
    });
    var sdb2 = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.US_WEST_1
    });
    var sdb3 = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.EU_WEST_1
    });
    var sdb4 = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.AP_SOUTHEAST_1
    });
    var sdb5 = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.AP_NORTHEAST_1
    });

    t.equal('sdb.amazonaws.com', sdb1.host(), '1) Endpoint is correct');
    t.equal('sdb.us-west-1.amazonaws.com', sdb2.host(), '2) Endpoint is correct');
    t.equal('sdb.eu-west-1.amazonaws.com', sdb3.host(), '3) Endpoint is correct');
    t.equal('sdb.ap-southeast-1.amazonaws.com', sdb4.host(), '4) Endpoint is correct');
    t.equal('sdb.ap-northeast-1.amazonaws.com', sdb5.host(), '5) Endpoint is correct');

    t.end();
});

test("test our own escape(...)", function (t) {
    var sdb = new SimpleDB({
        accessKeyId : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId : 'aws_account_id',
        region : amazon.US_WEST_1
    });

    var query1 = 'DomainName';
    var escQuery1 = esc(query1);
    t.equal(escQuery1, 'DomainName', 'Simple String (idempotent)');

    var query2 = 2;
    var escQuery2 = esc(query2);
    t.equal(escQuery2, '2', 'Simple Number Escape (idempotent)');

    var query3 = 'String Value';
    var escQuery3 = esc(query3);
    t.equal(escQuery3, 'String%20Value', 'Simple With a Space');

    var query4 = 'Hey @andychilton, read this! #liverpool';
    var escQuery4 = esc(query4);
    t.equal(escQuery4, 'Hey%20%40andychilton%2C%20read%20this%21%20%23liverpool', 'Something akin to a Tweet');

    var query5 = 'SELECT * FROM my_table';
    var escQuery5 = esc(query5);
    t.equal(escQuery5, 'SELECT%20%2A%20FROM%20my_table', 'Escaping of a select');

    t.end();
});

test("'failed param conversion' test", function (t) {
    // ToDo: check when we pass the wrong thing in
    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
