// --------------------------------------------------------------------------------------------------------------------
//
// amazon.js - the base class for all Amazon Web Services
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
// requires

var util = require("util");
var crypto = require('crypto');

// dependencies
var _ = require('underscore');
var xml2js = require('xml2js');

// our own library
var esc = require('../esc');
var awssum = require ("../awssum");
var awsSignatureV2 = require('./aws-signature-v2');

// --------------------------------------------------------------------------------------------------------------------
// constants

var MARK = 'amazon: ';

var US_EAST_1      = 'us-east-1';
var US_WEST_1      = 'us-west-1';
var US_WEST_2      = 'us-west-2';
var EU_WEST_1      = 'eu-west-1';
var AP_SOUTHEAST_1 = 'ap-southeast-1';
var AP_NORTHEAST_1 = 'ap-northeast-1';
var SA_EAST_1      = 'sa-east-1';
var US_GOV_WEST_1  = 'us-gov-west-1'; // See : http://aws.amazon.com/about-aws/globalinfrastructure/

var Region = {
    US_EAST_1      : true,
    US_WEST_1      : true,
    US_WEST_2      : true,
    EU_WEST_1      : true,
    AP_SOUTHEAST_1 : true,
    AP_NORTHEAST_1 : true,
    SA_EAST_1      : true,
    US_GOV_WEST_1  : true,
};

// create our XML parser
var parser = new xml2js.Parser({ normalize : false, trim : false, explicitRoot : true });

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Amazon = function(opts) {
    var self = this;
    var accessKeyId, secretAccessKey, awsAccountId, region, token;

    // call the superclass for initialisation
    Amazon.super_.call(this, opts);

    // check that we have each of these values
    if ( ! opts.accessKeyId ) {
        throw MARK + 'accessKeyID is required';
    }
    if ( ! opts.secretAccessKey ) {
        throw MARK + 'secretAccessKey is required';
    }
    if ( ! opts.region ) {
        throw MARK + 'region is required';
    }

    // set the local vars so the functions below can close over them
    accessKeyId         = opts.accessKeyId;
    secretAccessKey     = opts.secretAccessKey;
    region              = opts.region;
    if ( opts.awsAccountId ) {
        awsAccountId = opts.awsAccountId;
    }

    if ( opts.token ) {
        token = opts.token;
    }

    self.setAccessKeyId     = function(newStr) { accessKeyId = newStr; };
    self.setSecretAccessKey = function(newStr) { secretAccessKey = newStr; };
    self.setAwsAccountId    = function(newStr) { awsAccountId = newStr; };

    self.accessKeyId     = function() { return accessKeyId;     };
    self.secretAccessKey = function() { return secretAccessKey; };
    self.region          = function() { return region;          };
    self.awsAccountId    = function() { return awsAccountId;    };
    self.token           = function() { return token;           };

    return self;
};

// inherit from AwsSum
util.inherits(Amazon, awssum.AwsSum);

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting class

// see ../awssum.js for more details

Amazon.prototype.extractBody = function() {
    // most amazon services return XML, so override in inheriting classes if needed
    return 'xml';
};

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting (Amazon) class

// function version()              -> string (the version of this service)
// function signatureVersion()     -> string (the signature version used)
// function signatureMethod()      -> string (the signature method used)
// function strToSign(options)     -> string (the string that needs to be signed)
// function signature(strToSign)   -> string (the signature itself)
// function addSignature(options, signature) -> side effect, adds the signature to the 'options'

// This service uses (defaults to) the AWS Signature v2.
Amazon.prototype.signatureVersion = awsSignatureV2.signatureVersion;
Amazon.prototype.signatureMethod  = awsSignatureV2.signatureMethod;
Amazon.prototype.strToSign        = awsSignatureV2.strToSign;
Amazon.prototype.signature        = awsSignatureV2.signature;
Amazon.prototype.addSignature     = awsSignatureV2.addSignature;
Amazon.prototype.addCommonOptions = awsSignatureV2.addCommonOptions;

// --------------------------------------------------------------------------------------------------------------------
// exports

// constants
exports.US_EAST_1      = US_EAST_1;
exports.US_WEST_1      = US_WEST_1;
exports.US_WEST_2      = US_WEST_2;
exports.EU_WEST_1      = EU_WEST_1;
exports.AP_SOUTHEAST_1 = AP_SOUTHEAST_1;
exports.AP_NORTHEAST_1 = AP_NORTHEAST_1;
exports.US_GOV_WEST_1  = US_GOV_WEST_1;
exports.SA_EAST_1      = SA_EAST_1;

// object constructor
exports.Amazon = Amazon;

// --------------------------------------------------------------------------------------------------------------------
