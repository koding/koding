// --------------------------------------------------------------------------------------------------------------------
//
// cloudformation.js - class for AWS CloudFormation
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
var operations = require('./cloudformation-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'cloudformation: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "cloudformation.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "cloudformation.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "cloudformation.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "cloudformation.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "cloudformation.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "cloudformation.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "cloudformation.sa-east-1.amazonaws.com";
endPoint[amazon.US_GOV_WEST_1]  = "cloudformation.us-gov-west-1.amazonaws.com";

var version = '2010-05-15';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var CloudFormation = function(opts) {
    var self = this;

    // call the superclass for initialisation
    CloudFormation.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(CloudFormation, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

CloudFormation.prototype.host = function() {
    return endPoint[this.region()];
};

CloudFormation.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    CloudFormation.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.CloudFormation = CloudFormation;

// --------------------------------------------------------------------------------------------------------------------
