// --------------------------------------------------------------------------------------------------------------------
//
// ec2.js - class for GreenQloud Elastic Compute Cloud
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
// requires

// built-ins
var util = require('util');

// dependencies
var _ = require('underscore');

// our own
var awssum = require('../awssum');
var greenqloud = require('./greenqloud');
var operations = require('../amazon/ec2-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'ec2: ';

// From: http://support.greenqloud.com/entries/20020852-using-the-api
var endPoint = {};
endPoint[greenqloud.IS_1] = "api.greenqloud.com";

var version = '2012-04-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Ec2 = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Ec2.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from GreenQloud
util.inherits(Ec2, greenqloud.GreenQloud);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/greenqloud.js

Ec2.prototype.host = function() {
    return endPoint[this.region()];
};

Ec2.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Ec2.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Ec2 = Ec2;

// --------------------------------------------------------------------------------------------------------------------
