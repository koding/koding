// --------------------------------------------------------------------------------------------------------------------
//
// cloudwatch.js - class for AWS Elastic Load Balancing
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
var operations = require('./cloudwatch-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'cloudwatch: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "monitoring.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "monitoring.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "monitoring.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "monitoring.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "monitoring.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "monitoring.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "monitoring.sa-east-1.amazonaws.com";
endPoint[amazon.US_GOV_WEST_1]  = "monitoring.us-gov-west-1.amazonaws.com";

var version = '2010-08-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var CloudWatch = function(opts) {
    var self = this;

    // call the superclass for initialisation
    CloudWatch.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(CloudWatch, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

CloudWatch.prototype.host = function() {
    return endPoint[this.region()];
};

CloudWatch.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    CloudWatch.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.CloudWatch = CloudWatch;

// --------------------------------------------------------------------------------------------------------------------
