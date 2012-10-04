// --------------------------------------------------------------------------------------------------------------------
//
// rds.js - class for AWS Relational Database Service
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
var amazon = require('./amazon');
var operations = require('./rds-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'rds: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "rds.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "rds.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "rds.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "rds.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "rds.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "rds.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "rds.sa-east-1.amazonaws.com";
// endPoint[amazon.US_GOV_WEST_1]  = "...";

var version = '2012-04-23';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Rds = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Rds.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Rds, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Rds.prototype.host = function() {
    return endPoint[this.region()];
};

Rds.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Rds.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Rds = Rds;

// --------------------------------------------------------------------------------------------------------------------
