// --------------------------------------------------------------------------------------------------------------------
//
// fps.js - class for AWS Flexible Payments
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------
// requires

// built-ins
var util = require('util');
var crypto = require('crypto');

// dependencies
var _ = require('underscore');
var dateFormat = require('dateformat');

// our own
var awssum = require('../awssum');
var amazon = awssum.load('amazon/amazon');
var Sts = awssum.load('amazon/sts').Sts;
var operations = require('./fps-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'fps: ';

// From: http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/EndPoints.html
var endPoint = {};
endPoint['FPS-PROD']    = "fps.amazonaws.com";
endPoint['FPS-SANDBOX'] = "fps.sandbox.amazonaws.com";
// endPoint['']         = "authorize.payments-sandbox.amazon.com/cobranded-ui/actions/start";
// endPoint['']         = "authorize.payments.amazon.com/cobranded-ui/actions/start";

// From: http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAPIReference/DataTypesAndFPSWsdl.html
var version = '2010-08-28';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Fps = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Fps.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Fps, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from amazon.js

Fps.prototype.method = function() {
    return 'POST';
};

Fps.prototype.host = function(args) {
    return endPoint[this.region()];
};

Fps.prototype.version = function() {
    return version;
};

Fps.prototype.extractBody = function() {
    return 'xml';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Fps.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Fps = Fps;

// --------------------------------------------------------------------------------------------------------------------
