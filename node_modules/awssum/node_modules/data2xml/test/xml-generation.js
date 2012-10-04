// --------------------------------------------------------------------------------------------------------------------
//
// xml-generation.js - tests for node-data2xml
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var tap = require("tap"),
    test = tap.test,
    plan = tap.plan;
var data2xml = require('../data2xml');

var declaration = '<?xml version="1.0" encoding="utf-8"?>\n';

// --------------------------------------------------------------------------------------------------------------------

var tests = [
    {
        name : 'empty structure',
        element : 'topelement',
        data : {},
        exp : declaration + '<topelement></topelement>'
    },
    {
        name : 'one element structure',
        element : 'topelement',
        data : { second : 'value' },
        exp : declaration + '<topelement><second>value</second></topelement>'
    },
    {
        name : 'one element structure with an xmlns',
        element : 'topelement',
        data : { _attr : { xmlns : 'http://www.appsattic.com/xml/namespace' }, second : 'value' },
        exp : declaration + '<topelement xmlns="http://www.appsattic.com/xml/namespace"><second>value</second></topelement>'
    },
    {
        name : 'two elements',
        element : 'topelement',
        data : { second : 'val2', third : 'val3' },
        exp : declaration + '<topelement><second>val2</second><third>val3</third></topelement>'
    },
    {
        name : 'simple hierarchical elements',
        element : 'topelement',
        data : { simple : 'val2', complex : { test : 'val4' } },
        exp : declaration + '<topelement><simple>val2</simple><complex><test>val4</test></complex></topelement>'
    },
    {
        name : 'simple one element array',
        element : 'topelement',
        data : { array : [ { item : 'value' } ] },
        exp : declaration + '<topelement><array><item>value</item></array></topelement>'
    },
    {
        name : 'simple two element array #1',
        element : 'topelement',
        data : { array : [ { item : 'value1' }, 'value2' ] },
        exp : declaration + '<topelement><array><item>value1</item></array><array>value2</array></topelement>'
    },
    {
        name : 'simple two element array #2',
        element : 'topelement',
        data : { array : [ 'value1', 'value2' ] },
        exp : declaration + '<topelement><array>value1</array><array>value2</array></topelement>'
    },
    {
        name : 'simple two element array #3',
        element : 'topelement',
        data : { array : { item : [ 'value1', 'value2' ] } },
        exp : declaration + '<topelement><array><item>value1</item><item>value2</item></array></topelement>'
    },
    {
        name : 'complex 4 element array with some attributes',
        element : 'topelement',
        data : { item : [
            { _attr : { type : 'a' }, _value : 'val1' },
            { _attr : { type : 'b' }, _value : 'val2' },
            'val3',
            { _value : 'val4' },
        ] },
        exp : declaration + '<topelement><item type="a">val1</item><item type="b">val2</item><item>val3</item><item>val4</item></topelement>'
    },
];

test("some simple xml", function (t) {
    tests.forEach(function(test) {
        var xml = data2xml(test.element, test.data);
        t.equal(xml, test.exp, test.name);
    });

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
