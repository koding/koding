// --------------------------------------------------------------------------------------------------------------------
//
// autoscaling.js - class for AWS AutoScaling
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
var operations = require('./autoscaling-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'autoscaling: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "autoscaling.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "autoscaling.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "autoscaling.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "autoscaling.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "autoscaling.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "autoscaling.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "autoscaling.sa-east-1.amazonaws.com";
// endPoint[amazon.US_GOV_WEST_1]  = "";

var version = '2011-01-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var AutoScaling = function(opts) {
    var self = this;

    // call the superclass for initialisation
    AutoScaling.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(AutoScaling, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

AutoScaling.prototype.host = function() {
    return endPoint[this.region()];
};

AutoScaling.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    AutoScaling.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.AutoScaling = AutoScaling;

// --------------------------------------------------------------------------------------------------------------------
