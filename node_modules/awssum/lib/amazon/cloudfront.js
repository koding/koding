// --------------------------------------------------------------------------------------------------------------------
//
// cloudfront.js - class for AWS CloudFront
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
var crypto = require('crypto');

// dependencies
var _ = require('underscore');
var dateFormat = require('dateformat');
var data2xml = require('data2xml');

// our own
var awssum = require('../awssum');
var amazon = require('./amazon');
var operations = require('./cloudfront-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'cloudfront: ';

var version = '2010-11-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var CloudFront = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // call the superclass for initialisation
    CloudFront.super_.call(this, opts);

    return self;
};

// inherit from Amazon
util.inherits(CloudFront, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
CloudFront.prototype.host = function() {
    return 'cloudfront.amazonaws.com';
};

CloudFront.prototype.version = function() {
    return version;
};

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/RESTAuthentication.html
//
// Adds the common headers to this request.
CloudFront.prototype.addCommonOptions = function(options) {
    var self = this;

    // add in the date
    options.headers.Date = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
};

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/RESTAuthentication.html
//
// Returns a strToSign for this request.
CloudFront.prototype.strToSign = function(options) {
    var self = this;
    return options.headers.Date;
};

CloudFront.prototype.signature = function(strToSign) {
    var self = this;

    // sign the request string
    var signature = crypto
        .createHmac('sha1', self.secretAccessKey())
        .update(strToSign)
        .digest('base64');

    // console.log('Signature :', signature);

    return signature;
};

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/RESTAuthentication.html
//
// Adds the signature to the request.
CloudFront.prototype.addSignature = function(options, signature) {
    var self = this;
    options.headers.Authorization = 'AWS ' + self.accessKeyId() + ':' + signature;
};

CloudFront.prototype.extractBody = function() {
    return 'xml';
};

CloudFront.prototype.extractHeaders = function() {
    return new RegExp('^x-amzn-', 'i');
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    CloudFront.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.CloudFront = CloudFront;

// --------------------------------------------------------------------------------------------------------------------
