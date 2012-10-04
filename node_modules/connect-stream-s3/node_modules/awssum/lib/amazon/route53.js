// --------------------------------------------------------------------------------------------------------------------
//
// route53.js - class for AWS Route 53
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
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
var xml2js = require('xml2js');
var dateFormat = require('dateformat');
var data2xml = require('data2xml');

// our own
var awssum = require('../awssum');
var amazon = require('./amazon');
var operations = require('./route53-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'route53: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "route53.amazonaws.com";
// no other endpoints exist for this service

var version = '2011-05-05';

// create our XML parser
var parser = new xml2js.Parser({ normalize : false, trim : false, explicitRoot : true });

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Route53 = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Route53.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Route53, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from amazon.js

// Route53.prototype.method() -> 'GET'

Route53.prototype.host = function(args) {
    return endPoint[this.region()];
};

Route53.prototype.version = function() {
    return version;
};

// From: http://docs.amazonwebservices.com/Route53/latest/DeveloperGuide/RESTAuthentication.html#StringToSign
//
// Returns a strToSign for this request.
Route53.prototype.strToSign = function(options) {
    var self = this;
    return options.headers.Date;
};

// From: http://docs.amazonwebservices.com/Route53/latest/DeveloperGuide/RESTAuthentication.html#AuthorizationHeader
//
// Adds the signature to the request.
Route53.prototype.addSignature = function(options, signature) {
    var self = this;
    options.headers['X-Amzn-Authorization'] = 'AWS3-HTTPS AWSAccessKeyId=' + self.accessKeyId()
        + ',Algorithm=' + self.signatureMethod()
        + ',Signature=' + signature;
};

// From: http://docs.amazonwebservices.com/Route53/latest/APIReference/Headers.html
//
// Adds the common headers to this request.
Route53.prototype.addCommonOptions = function(options) {
    var self = this;

    // add in the date
    options.headers.Date = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Route53.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Route53 = Route53;

// --------------------------------------------------------------------------------------------------------------------
