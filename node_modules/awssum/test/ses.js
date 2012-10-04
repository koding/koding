// --------------------------------------------------------------------------------------------------------------------
//
// ses.js - test for AWS Simple Email Service
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
var amazon;
var sesService;

// --------------------------------------------------------------------------------------------------------------------
// basic tests

test("load ses", function (t) {
    sesService = require("../lib/amazon/ses");
    t.ok(sesService, 'object loaded');

    amazon = require("../lib/amazon/amazon");
    t.ok(amazon, 'object loaded');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
