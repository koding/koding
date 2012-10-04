// --------------------------------------------------------------------------------------------------------------------
//
// sts.js - class for AWS Security Token Service
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
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
var amazon = require('./amazon');
var operations = require('./sts-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'sts: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "sts.amazonaws.com";
// no other endpoints exist for this service

var version = '2011-06-15';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Sts = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Sts.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Sts, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Sts.prototype.host = function() {
    return endPoint[this.region()];
};

Sts.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Sts.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Sts = Sts;

// --------------------------------------------------------------------------------------------------------------------
