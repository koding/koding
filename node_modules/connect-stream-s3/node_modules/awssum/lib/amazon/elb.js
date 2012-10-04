// --------------------------------------------------------------------------------------------------------------------
//
// elb.js - class for AWS Elastic Load Balancing
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
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
var operations = require('./elb-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'elb: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "elasticloadbalancing.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "elasticloadbalancing.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "elasticloadbalancing.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "elasticloadbalancing.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "elasticloadbalancing.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "elasticloadbalancing.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "elasticloadbalancing.sa-east-1.amazonaws.com";
// endPoint[amazon.US_GOV_WEST_1]  = "...";

var version = '2011-08-15';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Elb = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Elb.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Elb, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Elb.prototype.host = function() {
    return endPoint[this.region()];
};

Elb.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Elb.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Elb = Elb;

// --------------------------------------------------------------------------------------------------------------------
