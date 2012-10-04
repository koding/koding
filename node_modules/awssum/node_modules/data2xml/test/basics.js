// --------------------------------------------------------------------------------------------------------------------
//
// basics.js - tests for node-data2xml
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

// --------------------------------------------------------------------------------------------------------------------

test("some simple entities", function (t) {
    var test1 = data2xml.entitify('<hello>');
    var exp1 = '&lt;hello&gt;';
    t.equal(test1, exp1, 'LT and GT entitified correctly');

    var test2 = data2xml.entitify('\'&\"');
    var exp2 = '&apos;&amp;&quot;';
    t.equal(test2, exp2, 'other entities');

    t.end();
});

test("making some elements", function (t) {
    var test1 = data2xml.makeStartTag('tagme');
    var exp1 = '<tagme>';
    t.equal(test1, exp1, 'simple start tag');

    var test2 = data2xml.makeEndTag('tagme');
    var exp2 = '</tagme>';
    t.equal(test2, exp2, 'simple end tag');

    var test3 = data2xml.makeStartTag('tagme', { attr : 'value' });
    var exp3 = '<tagme attr="value">';
    t.equal(test3, exp3, '1) complex start tag');

    var test4 = data2xml.makeStartTag('tagme', { attr : '<anothertag>' });
    var exp4 = '<tagme attr="&lt;anothertag&gt;">';
    t.equal(test4, exp4, '2) complex start tag');

    var test5 = data2xml.makeStartTag('tagme', { attr1 : '<anothertag>', attr2 : 'val2' });
    var exp5 = '<tagme attr1="&lt;anothertag&gt;" attr2="val2">';
    t.equal(test5, exp5, '3) complex start tag');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
