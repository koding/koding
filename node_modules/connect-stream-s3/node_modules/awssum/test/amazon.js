// --------------------------------------------------------------------------------------------------------------------
//
// amazon.js - test for AWS Amazon
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
    _ = require('underscore'),
    test = tap.test,
    plan = tap.plan;
var awssum = require('../');
var amazon;
var esc = require('../lib/esc.js');

// --------------------------------------------------------------------------------------------------------------------
// basic tests

test("load amazon", function (t) {
    amazon = awssum.load('amazon/amazon');
    t.ok(amazon, 'object loaded');
    t.end();
})

test("create amazon object", function (t) {
    t.equal('us-east-1',      amazon.US_EAST_1,      'US East 1'     );
    t.equal('us-west-1',      amazon.US_WEST_1,      'US West 1'     );
    t.equal('eu-west-1',      amazon.EU_WEST_1,      'EU West 1'     );
    t.equal('ap-southeast-1', amazon.AP_SOUTHEAST_1, 'AP SouthEast 1');
    t.equal('ap-northeast-1', amazon.AP_NORTHEAST_1, 'AP NorthEast 1');
    t.end();
});

test("test addParam", function (t) {
    var amz = new amazon.Amazon({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    var params = [];
    var result = [
        { 'name' : 'Name',  'value' : 'Value' }
    ];
    awssum.addParam(params, 'Name', 'Value');
    t.ok(_.isEqual(params, result), 'Deep compare of params');

    t.end();
});

test("test addParamIfDefined", function (t) {
    var amz = new amazon.Amazon({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    var params1 = [];
    var result1 = [
        { 'name' : 'Name',  'value' : 'Value' }
    ];
    awssum.addParamIfDefined(params1, 'Name', 'Value');
    t.ok(_.isEqual(params1, result1), 'Deep compare of params');

    var params2 = [];
    var result2 = [];
    awssum.addParamIfDefined(params2, 'Name', undefined);
    t.ok(_.isEqual(params2, result2), 'Deep compare of (empty) params');

    t.end();
});

test("test our own esc(...)", function (t) {
    var amz = new amazon.Amazon({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
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

test("test strToSign", function (t) {
    var amz = new amazon.Amazon({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });

    var paramsEmpty = [];
    var strToSignEmpty = amz.strToSign({ method : 'GET', host : '', path : '/', params : paramsEmpty });
    t.equal(strToSignEmpty, "GET\n\n/\n", 'strToSign of empty params');

    // doesn't matter _what_ these values are, we just need something (ie. 'version' doesn't matter if it's wrong)
    var paramsCommon = [];
    paramsCommon.push({ 'name' : 'AWSAccessKeyId', 'value' : amz.accessKeyId() });
    paramsCommon.push({ 'name' : 'Version', 'value' : '2009-04-15' });
    paramsCommon.push({ 'name' : 'Timestamp', 'value' : '2011-10-17T18:35:02.878Z' });
    paramsCommon.push({ 'name' : 'SignatureVersion', 'value' : 2 });
    paramsCommon.push({ 'name' : 'SignatureMethod', 'value' : 'HmacSHA256' });
    var strToSignCommon = amz.strToSign({ method : 'GET', host : '', path : '/', params : paramsCommon });
    t.equal(strToSignCommon, "GET\n\n/\nAWSAccessKeyId=access_key_id&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-10-17T18%3A35%3A02.878Z&Version=2009-04-15", 'strToSign of common params');

    t.end();
});

test("test signature", function (t) {
    var amz = new amazon.Amazon({
        accessKeyId     : 'access_key_id',
        secretAccessKey : 'secret_access_key',
        awsAccountId    : 'aws_account_id',
        region          : amazon.US_WEST_1
    });
    var strToSign;

    var paramsEmpty = [];
    strToSign = amz.strToSign({ method : 'GET', host : '', path : '/', params : paramsEmpty });
    var sigEmpty = amz.signature(strToSign);
    t.equal(sigEmpty, 'xkZtou/+82NuDSRdyi5iEw5uPbRunNcjy7IKD+sgkOo=', 'Signature of empty params');

    // doesn't matter _what_ these values are, we just need something (ie. 'version' doesn't matter if it's wrong)
    var paramsCommon = [];
    paramsCommon.push({ 'name' : 'AWSAccessKeyId', 'value' : amz.accessKeyId() });
    paramsCommon.push({ 'name' : 'Version', 'value' : '2009-04-15' });
    paramsCommon.push({ 'name' : 'Timestamp', 'value' : '2011-10-17T18:35:02.878Z' });
    paramsCommon.push({ 'name' : 'SignatureVersion', 'value' : 2 });
    paramsCommon.push({ 'name' : 'SignatureMethod', 'value' : 'HmacSHA256' });
    strToSign = amz.strToSign({ method : 'GET', host : '', path : '/', params : paramsCommon });
    var sigCommon = amz.signature(strToSign);
    t.equal(sigEmpty, 'xkZtou/+82NuDSRdyi5iEw5uPbRunNcjy7IKD+sgkOo=', 'Signature of common params');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
