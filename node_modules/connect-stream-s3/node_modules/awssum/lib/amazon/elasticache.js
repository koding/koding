// --------------------------------------------------------------------------------------------------------------------
//
// elasticache.js - class for AWS Elasticache
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
var operations = require('./elasticache-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'elasticache: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "elasticache.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "elasticache.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "elasticache.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "elasticache.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "elasticache.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "elasticache.ap-northeast-1.amazonaws.com";
endPoint[amazon.SA_EAST_1]      = "elasticache.sa-east-1.amazonaws.com";
// endPoint[amazon.US_GOV_WEST_1]  = "...";

var version = '2011-07-15';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var ElastiCache = function(opts) {
    var self = this;

    // call the superclass for initialisation
    ElastiCache.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(ElastiCache, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

ElastiCache.prototype.host = function() {
    return endPoint[this.region()];
};

ElastiCache.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    ElastiCache.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.ElastiCache = ElastiCache;

// --------------------------------------------------------------------------------------------------------------------
