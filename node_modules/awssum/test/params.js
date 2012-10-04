// --------------------------------------------------------------------------------------------------------------------
//
// params.js - test for params
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
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

// --------------------------------------------------------------------------------------------------------------------

test("test addParam", function (t) {
    var params = [];
    var result = [
        { 'name' : 'Name',  'value' : 'Value' }
    ];
    awssum.addParam(params, 'Name', 'Value');
    t.ok(_.isEqual(params, result), 'Deep compare of params');

    t.end();
});

test("test addParamIfDefined", function (t) {
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

test("test addParamArray", function (t) {
    var values1 = [ 'Hi', 'There' ];
    var params1 = [];
    var result1 = [
        { 'name' : 'Name.member.1', 'value' : 'Hi' },
        { 'name' : 'Name.member.2', 'value' : 'There' },
    ];
    awssum.addParamArray(params1, 'Name', values1, 'member');
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParamArray');

    var values2 = [];
    var params2 = [];
    var result2 = [];
    awssum.addParamArray(params2, 'Name', values2, 'member');
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParamArray (empty)');

    var values3 = [ 'Hi', 'There' ];
    var params3 = [];
    var result3 = [
        { 'name' : 'Name.1', 'value' : 'Hi' },
        { 'name' : 'Name.2', 'value' : 'There' },
    ];
    awssum.addParamArray(params3, 'Name', values3);
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParamArray (no prefix)');

    t.end();
});

test("test addParamArraySet", function (t) {
    var values1 = 'Hello, World!';
    var params1 = [];
    var result1 = [
        { 'name' : 'Name.1.SetName', 'value' : 'Hello, World!' },
    ];
    awssum.addParamArraySet(params1, 'Name', 'SetName', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParamArray (single value)');

    var values2 = [ 'Hello, World!', 'Hi Everyone' ];
    var params2 = [];
    var result2 = [
        { 'name' : 'Name.1.SetName', 'value' : 'Hello, World!' },
        { 'name' : 'Name.2.SetName', 'value' : 'Hi Everyone' },
    ];
    awssum.addParamArraySet(params2, 'Name', 'SetName', values2);
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParamArray (multiple values)');

    var values3 = [];
    var params3 = [];
    var result3 = [];
    awssum.addParamArraySet(params3, 'Name', 'SetName', values3);
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParamArray (empty array)');

    t.end();
});

test("test addParam2dArray", function (t) {
    var values1 = [];
    var params1 = [];
    var result1 = [];
    awssum.addParam2dArray(params1, 'Name', 'SetName', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParam2dArray (empty array)');

    var values2;
    var params2 = [];
    var result2 = [];
    awssum.addParam2dArray(params2, 'Name', 'SetName', values2);
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParam2dArray (undefined value)');

    var values3 = [
        [ 'red', 'blue', 'green'],
        [ 'yellow', 'cyan', 'magenta' ],
    ];
    var params3 = [];
    var result3 = [
        { name : 'User.1.Colour.1', value : 'red' },
        { name : 'User.1.Colour.2', value : 'blue' },
        { name : 'User.1.Colour.3', value : 'green' },
        { name : 'User.2.Colour.1', value : 'yellow' },
        { name : 'User.2.Colour.2', value : 'cyan' },
        { name : 'User.2.Colour.3', value : 'magenta' },
    ];
    awssum.addParam2dArray(params3, 'User', 'Colour', values3);
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParam2dArray');

    t.end();
});

test("test addParam2dArraySet", function (t) {
    var values1 = [];
    var params1 = [];
    var result1 = [];
    awssum.addParam2dArraySet(params1, 'Name', 'SetName', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParam2dArray (empty array)');

    var values2;
    var params2 = [];
    var result2 = [];
    awssum.addParam2dArraySet(params2, 'Name', 'SetName', values2);
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParam2dArray (undefined value)');

    var values3 = [
        [ 'red', 'blue', 'green'],
        [ 'yellow', 'cyan', 'magenta' ],
    ];
    var params3 = [];
    var result3 = [
        { name : 'User.1.Colour.1.Name', value : 'red' },
        { name : 'User.1.Colour.2.Name', value : 'blue' },
        { name : 'User.1.Colour.3.Name', value : 'green' },
        { name : 'User.2.Colour.1.Name', value : 'yellow' },
        { name : 'User.2.Colour.2.Name', value : 'cyan' },
        { name : 'User.2.Colour.3.Name', value : 'magenta' },
    ];
    awssum.addParam2dArraySet(params3, 'User', 'Colour', 'Name', values3);
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParam2dArraySet');

    t.end();
});

test("test addParamArrayOfObjects", function (t) {
    var values1 = [];
    var params1 = [];
    var result1 = [];
    awssum.addParamArrayOfObjects(params1, 'Anything', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParamArrayOfObjects (empty array)');

    var values2 = [
        { 'Username' : 'chilts', 'Logins' : 12 },
        { 'Username' : 'bob',    'Logins' :  1 },
    ];
    var params2 = [];
    var result2 = [
        { name : 'User.1.Username', value : 'chilts' },
        { name : 'User.1.Logins',   value : '12' },
        { name : 'User.2.Username', value : 'bob' },
        { name : 'User.2.Logins',   value :  '1' },
    ];
    awssum.addParamArrayOfObjects(params2, 'User', values2);
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParamArrayOfObjects');

    var values3 = [
        { 'Username' : 'chilts', 'Logins' : 12 },
        { 'Username' : 'bob',    'Logins' :  1 },
    ];
    var params3 = [];
    var result3 = [
        { name : 'User.member.1.Username', value : 'chilts' },
        { name : 'User.member.1.Logins',   value : '12' },
        { name : 'User.member.2.Username', value : 'bob' },
        { name : 'User.member.2.Logins',   value :  '1' },
    ];
    awssum.addParamArrayOfObjects(params3, 'User', values3, 'member');
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParamArrayOfObjects (with prefix)');

    t.end();
});

test("test addParamData", function (t) {
    var values0 = 'Hiya';
    var params0 = [];
    var result0 = [
        { 'name' : 'Message', 'value' : 'Hiya' },
    ];
    awssum.addParamData(params0, 'Message', values0);
    t.ok(_.isEqual(params0, result0), 'Deep compare of addParamData (a value)');

    var values1 = [];
    var params1 = [];
    var result1 = [];
    awssum.addParamData(params1, 'Anything', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParamData (empty array)');

    var values2 = [
        { 'Username' : 'chilts', 'Logins' : 12 },
        { 'Username' : 'bob',    'Logins' :  1 },
    ];
    var params2 = [];
    var result2 = [
        { name : 'User.1.Username', value : 'chilts' },
        { name : 'User.1.Logins',   value : '12' },
        { name : 'User.2.Username', value : 'bob' },
        { name : 'User.2.Logins',   value :  '1' },
    ];
    awssum.addParamData(params2, 'User', values2);
    t.ok(_.isEqual(params2, result2), 'Deep compare of addParamData');

    var values3 = [
        { 'Username' : 'chilts', 'Logins' : 12 },
        { 'Username' : 'bob',    'Logins' :  1 },
    ];
    var params3 = [];
    var result3 = [
        { name : 'User.member.1.Username', value : 'chilts' },
        { name : 'User.member.1.Logins',   value : '12' },
        { name : 'User.member.2.Username', value : 'bob' },
        { name : 'User.member.2.Logins',   value :  '1' },
    ];
    awssum.addParamData(params3, 'User', values3, 'member');
    t.ok(_.isEqual(params3, result3), 'Deep compare of addParamData (with prefix)');

    var values4 = [
        {
            'Username' : 'chilts',
            'Logins' : 12,
            'FavColours' : [ 'red', 'green', 'blue' ],
        },
        {
            'Username' : 'bob',
            'Logins' :  1,
            'FavColours' : [ 'cyan', 'magenta', 'yellow' ],
        },
    ];
    var params4 = [];
    var params4Prefix = [];
    var result4 = [
        { name : 'User.1.Username', value : 'chilts' },
        { name : 'User.1.Logins',   value : '12' },
        { name : 'User.1.FavColours.1', value : 'red' },
        { name : 'User.1.FavColours.2', value : 'green' },
        { name : 'User.1.FavColours.3', value : 'blue' },
        { name : 'User.2.Username', value : 'bob' },
        { name : 'User.2.Logins',   value :  '1' },
        { name : 'User.2.FavColours.1', value : 'cyan' },
        { name : 'User.2.FavColours.2', value : 'magenta' },
        { name : 'User.2.FavColours.3', value : 'yellow' },
    ];
    var result4Prefix = [
        { name : 'User.member.1.Username', value : 'chilts' },
        { name : 'User.member.1.Logins',   value : '12' },
        { name : 'User.member.1.FavColours.member.1', value : 'red' },
        { name : 'User.member.1.FavColours.member.2', value : 'green' },
        { name : 'User.member.1.FavColours.member.3', value : 'blue' },
        { name : 'User.member.2.Username', value : 'bob' },
        { name : 'User.member.2.Logins',   value :  '1' },
        { name : 'User.member.2.FavColours.member.1', value : 'cyan' },
        { name : 'User.member.2.FavColours.member.2', value : 'magenta' },
        { name : 'User.member.2.FavColours.member.3', value : 'yellow' },
    ];
    awssum.addParamData(params4, 'User', values4);
    awssum.addParamData(params4Prefix, 'User', values4, 'member');
    t.ok(_.isEqual(params4, result4), 'Deep compare of addParamData (with extra array)');
    t.ok(_.isEqual(params4Prefix, result4Prefix), 'Deep compare of addParamData (with extra array and prefix)');

    var values5 = [
        {
            'Username' : 'chilts',
            'Logins' : 12,
            'FavColours' : [ 'red', 'green', 'blue' ],
            'Dimensions' : { 'X' : 10, 'Y' : 20 },
        },
        {
            'Username' : 'bob',
            'Logins' :  1,
            'FavColours' : [ 'cyan', 'magenta', 'yellow' ],
            'Dimensions' : { 'X' : 64, 'Y' : 80 },
        },
    ];
    var params5 = [];
    var params5Prefix = [];
    var result5 = [
        { name : 'User.1.Username', value : 'chilts' },
        { name : 'User.1.Logins',   value : '12' },
        { name : 'User.1.FavColours.1', value : 'red' },
        { name : 'User.1.FavColours.2', value : 'green' },
        { name : 'User.1.FavColours.3', value : 'blue' },
        { name : 'User.1.Dimensions.X', value : '10' },
        { name : 'User.1.Dimensions.Y', value : '20' },
        { name : 'User.2.Username', value : 'bob' },
        { name : 'User.2.Logins',   value :  '1' },
        { name : 'User.2.FavColours.1', value : 'cyan' },
        { name : 'User.2.FavColours.2', value : 'magenta' },
        { name : 'User.2.FavColours.3', value : 'yellow' },
        { name : 'User.2.Dimensions.X', value : '64' },
        { name : 'User.2.Dimensions.Y', value : '80' },
    ];
    var result5Prefix = [
        { name : 'User.member.1.Username', value : 'chilts' },
        { name : 'User.member.1.Logins',   value : '12' },
        { name : 'User.member.1.FavColours.member.1', value : 'red' },
        { name : 'User.member.1.FavColours.member.2', value : 'green' },
        { name : 'User.member.1.FavColours.member.3', value : 'blue' },
        { name : 'User.member.1.Dimensions.X', value : '10' },
        { name : 'User.member.1.Dimensions.Y', value : '20' },
        { name : 'User.member.2.Username', value : 'bob' },
        { name : 'User.member.2.Logins',   value :  '1' },
        { name : 'User.member.2.FavColours.member.1', value : 'cyan' },
        { name : 'User.member.2.FavColours.member.2', value : 'magenta' },
        { name : 'User.member.2.FavColours.member.3', value : 'yellow' },
        { name : 'User.member.2.Dimensions.X', value : '64' },
        { name : 'User.member.2.Dimensions.Y', value : '80' },
    ];
    awssum.addParamData(params5, 'User', values5);
    awssum.addParamData(params5Prefix, 'User', values5, 'member');
    t.ok(_.isEqual(params5, result5), 'Deep compare of addParamData (with extra array set)');
    t.ok(_.isEqual(params5Prefix, result5Prefix), 'Deep compare of addParamData (with extra array set and prefix)');

    // From: http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_PutMetricData.html
    //
    // MetricData.member.1.MetricName=buffers
    // MetricData.member.1.Unit=Bytes
    // MetricData.member.1.Value=231434333
    // MetricData.member.1.Dimensions.member.1.Name=InstanceID
    // MetricData.member.1.Dimensions.member.1.Value=i-aaba32d5
    // MetricData.member.1.Dimensions.member.2.Name=InstanceType
    // MetricData.member.1.Dimensions.member.2.Value=m1.micro
    // MetricData.member.2.MetricName=latency
    // MetricData.member.2.Unit=Milliseconds
    // MetricData.member.2.Value=23
    // MetricData.member.2.Dimensions.member.1.Name=InstanceID
    // MetricData.member.2.Dimensions.member.1.Value=i-aaba32d4
    // MetricData.member.2.Dimensions.member.2.Name=InstanceType
    // MetricData.member.2.Dimensions.member.2.Value=m1.small

    var values6 = [
        {
            MetricName : 'buffers',
            Unit : 'Bytes',
            Value : 231434333,
            Dimensions : [
                { Name : 'InstanceId',   Value : 'i-aaba32d5', },
                { Name : 'InstanceType', Value : 'm1.micro',    },
            ],
        },
        {
            MetricName : 'latency',
            Unit : 'Milliseconds',
            Value : 23,
            Dimensions : [
                { Name : 'InstanceId',   Value : 'i-aaba32d4', },
                { Name : 'InstanceType', Value : 'm1.small',   },
            ],
        },
    ];
    var params6 = [];
    var result6 = [
        { name : 'MetricData.member.1.MetricName', value : 'buffers' },
        { name : 'MetricData.member.1.Unit', value : 'Bytes' },
        { name : 'MetricData.member.1.Value', value : '231434333' },
        { name : 'MetricData.member.1.Dimensions.member.1.Name', value : 'InstanceId' },
        { name : 'MetricData.member.1.Dimensions.member.1.Value', value : 'i-aaba32d5' },
        { name : 'MetricData.member.1.Dimensions.member.2.Name', value : 'InstanceType' },
        { name : 'MetricData.member.1.Dimensions.member.2.Value', value : 'm1.micro' },
        { name : 'MetricData.member.2.MetricName', value : 'latency' },
        { name : 'MetricData.member.2.Unit', value : 'Milliseconds' },
        { name : 'MetricData.member.2.Value', value : '23' },
        { name : 'MetricData.member.2.Dimensions.member.1.Name', value : 'InstanceId' },
        { name : 'MetricData.member.2.Dimensions.member.1.Value', value : 'i-aaba32d4' },
        { name : 'MetricData.member.2.Dimensions.member.2.Name', value : 'InstanceType' },
        { name : 'MetricData.member.2.Dimensions.member.2.Value', value : 'm1.small' },
    ];
    awssum.addParamData(params6, 'MetricData', values6, 'member');
    t.ok(_.isEqual(params6, result6), 'Deep compare of addParamData (real data)');

    t.end();
});

test("test addParamData (Real Life 1)", function (t) {
    var values1 = [
        {
            Name : 'instance-type',
            Value : [ 'm1.small', 'm1.large' ]
        },
        {
            Name : 'block-mapping-device-status',
            Value : [ 'attached' ]
        }
    ];
    var params1 = [];
    var result1 = [
        { 'name' : 'Filter.1.Name', 'value' : 'instance-type' },
        { 'name' : 'Filter.1.Value.1', 'value' : 'm1.small' },
        { 'name' : 'Filter.1.Value.2', 'value' : 'm1.large' },
        { 'name' : 'Filter.2.Name', 'value' : 'block-mapping-device-status' },
        { 'name' : 'Filter.2.Value.1', 'value' : 'attached' },
    ];
    awssum.addParamData(params1, 'Filter', values1);
    t.ok(_.isEqual(params1, result1), 'Deep compare of addParamData (Real Life 1)');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
