// --------------------------------------------------------------------------------------------------------------------
//
// elasticbeanstalk.js - class for AWS Elastic Compute Cloud
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
var operations = require('./elasticbeanstalk-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'elasticbeanstalk: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "elasticbeanstalk.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "elasticbeanstalk.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "elasticbeanstalk.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "elasticbeanstalk.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "elasticbeanstalk.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "elasticbeanstalk.ap-northeast-1.amazonaws.com";
// endPoint[amazon.SA_EAST_1]      = "";
// endPoint[amazon.US_GOV_WEST_1]  = "";

var version = '2010-12-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var ElasticBeanstalk = function(opts) {
    var self = this;

    // call the superclass for initialisation
    ElasticBeanstalk.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(ElasticBeanstalk, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

ElasticBeanstalk.prototype.host = function() {
    return endPoint[this.region()];
};

ElasticBeanstalk.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    ElasticBeanstalk.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.ElasticBeanstalk = ElasticBeanstalk;

// --------------------------------------------------------------------------------------------------------------------

