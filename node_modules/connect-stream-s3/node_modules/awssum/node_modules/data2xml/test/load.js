// --------------------------------------------------------------------------------------------------------------------
//
// load.js - tests for node-data2xml
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
var data2xml;

// --------------------------------------------------------------------------------------------------------------------

test("load data2xml", function (t) {
    data2xml = require("../data2xml");
    t.ok(data2xml, "package loaded");

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
