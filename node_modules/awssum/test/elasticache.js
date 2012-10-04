// --------------------------------------------------------------------------------------------------------------------
//
// elasticache.js - test for AWS Simple Email Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenelasticache/MIT
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
var elastiCacheService;

// --------------------------------------------------------------------------------------------------------------------
// basic tests

test("load elasticache", function (t) {
    amazon = awssum.load('amazon/amazon');
    t.ok(amazon, 'object loaded');

    elastiCacheService = awssum.load('amazon/elasticache');
    t.ok(elastiCacheService, 'object loaded');

    t.end();
});

// --------------------------------------------------------------------------------------------------------------------
