// --------------------------------------------------------------------------------------------------------------------
//
// dynamodb.js - class for AWS DynamoDB
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
var operations = require('./dynamodb-config');
var awsSignatureV4 = require('./aws-signature-v4');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'dynamodb: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "dynamodb.us-east-1.amazonaws.com";
endPoint[amazon.US_WEST_1]      = "dynamodb.us-west-1.amazonaws.com";
endPoint[amazon.US_WEST_2]      = "dynamodb.us-west-2.amazonaws.com";
endPoint[amazon.EU_WEST_1]      = "dynamodb.eu-west-1.amazonaws.com";
endPoint[amazon.AP_SOUTHEAST_1] = "dynamodb.ap-southeast-1.amazonaws.com";
endPoint[amazon.AP_NORTHEAST_1] = "dynamodb.ap-northeast-1.amazonaws.com";
// no other endpoints exist (yet) for this service

var version = '20111205';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var DynamoDB = function(opts) {
    var self = this;

    // call the superclass for initialisation
    DynamoDB.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    // create an STS client to use for getting the session tokens
    self._sts = new Sts(opts);

    return self;
};

// inherit from Amazon
util.inherits(DynamoDB, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from amazon.js

DynamoDB.prototype.method = function() {
    return 'POST';
};

DynamoDB.prototype.host = function(args) {
    return endPoint[this.region()];
};

DynamoDB.prototype.version = function() {
    return version;
};

DynamoDB.prototype.extractBody = function() {
    // DynamoDB always returns JSON
    return 'json';
};

// ----------------------------------------------------------------------------
// AWS Signature v4

DynamoDB.prototype.scope = function() {
    return 'dynamodb';
};

DynamoDB.prototype.serviceName = function() {
    return 'DynamoDB';
};

DynamoDB.prototype.needsTarget = function() {
    return true;
};

// This service uses the AWS Signature v4.
// Hopefully, it fulfills : http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/requestauth.html
DynamoDB.prototype.strToSign        = awsSignatureV4.strToSign;
DynamoDB.prototype.signature        = awsSignatureV4.signature;
DynamoDB.prototype.addSignature     = awsSignatureV4.addSignature;
DynamoDB.prototype.addCommonOptions = awsSignatureV4.addCommonOptions;
DynamoDB.prototype.contentType      = function() { return 'application/x-amz-json-1.0'; };

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    DynamoDB.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.DynamoDB = DynamoDB;

// --------------------------------------------------------------------------------------------------------------------
