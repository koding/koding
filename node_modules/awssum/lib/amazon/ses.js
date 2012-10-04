//-------------------------------------------------------------------------------------------------------------------
//
// ses.js - class for AWS Simple Email Service
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
var xml2js = require('xml2js');
var dateFormat = require('dateformat');

// our own
var awssum = require('../awssum');
var amazon = require('./amazon');
var operations = require('./ses-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'ses: ';

// From: http://aws.amazon.com/releasenotes/Amazon-SES
var version = '2012-07-17';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Ses = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // call the superclass for initialisation
    Ses.super_.call(this, opts);

    return self;
};

// inherit from Amazon
util.inherits(Ses, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Ses.prototype.method = function() {
    return 'POST';
};

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
Ses.prototype.host = function() {
    return 'email.us-east-1.amazonaws.com';
};

Ses.prototype.version = function() {
    return version;
};

Ses.prototype.addCommonOptions = function(options) {
    var self = this;

    // get the date in both %Y-%m-%dT%H:%M:%SZ and regular
    var date = new Date();
    var dateHeader = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");
    var timestamp = date.toISOString();

    // add the date header
    options.headers.Date = dateHeader;
    options.headers['Content-Type'] = 'application/x-www-form-urlencoded';

    // add in the common form fields
    options.form = options.form || [];
    options.form.push({ 'name' : 'AWSAccessKeyId', 'value' : this.accessKeyId() });
    options.form.push({ 'name' : 'Timestamp', 'value' : timestamp });
    options.form.push({ 'name' : 'Version', 'value' : self.version() });

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
};

// From: http://docs.amazonwebservices.com/ses/latest/DeveloperGuide/index.html?HMACShaSignatures.html
Ses.prototype.strToSign = function(options) {
    var self = this;

    return options.headers.Date;
};

Ses.prototype.addSignature = function(options, signature) {
    var self = this;

    // do the extra headers (including the signature)
    options.headers['X-Amzn-Authorization'] = 'AWS3-HTTPS AWSAccessKeyId=' + self.accessKeyId()
        + ', Signature=' + signature
        + ', Algorithm=' + self.signatureMethod();
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Ses.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Ses = Ses;

// --------------------------------------------------------------------------------------------------------------------
