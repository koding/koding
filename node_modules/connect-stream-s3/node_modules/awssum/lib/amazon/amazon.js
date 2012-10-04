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
    var accessKeyId, secretAccessKey, awsAccountId, region;

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

    self.setAccessKeyId     = function(newStr) { accessKeyId = newStr; };
    self.setSecretAccessKey = function(newStr) { secretAccessKey = newStr; };
    self.setAwsAccountId    = function(newStr) { awsAccountId = newStr; };

    self.accessKeyId     = function() { return accessKeyId;     };
    self.secretAccessKey = function() { return secretAccessKey; };
    self.awsAccountId    = function() { return awsAccountId;    };
    self.region          = function() { return region;          };

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

Amazon.prototype.addCommonOptions = function(options) {
    var self = this;

    // get the date in UTC : %Y-%m-%dT%H:%M:%SZ
    var date = (new Date()).toISOString();

    // add in the common params
    options.params.push({ 'name' : 'AWSAccessKeyId', 'value' : self.accessKeyId() });
    options.params.push({ 'name' : 'SignatureVersion', 'value' : self.signatureVersion() });
    options.params.push({ 'name' : 'SignatureMethod', 'value' : self.signatureMethod() });
    options.params.push({ 'name' : 'Timestamp', 'value' : date });
    options.params.push({ 'name' : 'Version', 'value' : self.version() });

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
};

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting (Amazon) class

// function version()              -> string (the version of this service)
// function signatureVersion()     -> string (the signature version used)
// function signatureMethod()      -> string (the signature method used)
// function strToSign(options)     -> string (the string that needs to be signed)
// function signature(strToSign)   -> string (the signature itself)
// function addSignature(options, signature) -> side effect, adds the signature to the 'options'

// Amazon.prototype.version // no default

Amazon.prototype.signatureVersion = function() {
    return 2;
};

Amazon.prototype.signatureMethod = function() {
    return 'HmacSHA256';
};

Amazon.prototype.strToSign = function(options) {
    var self = this;

    // create the strToSign for this request
    var strToSign = options.method + "\n" + options.host.toLowerCase() + "\n" + options.path + "\n";

    // now add on all of the params (after being sorted)
    var pvPairs = _(options.params)
        .chain()
        .sortBy(function(p) { return p.name; })
        .map(function(v, i) { return '' + esc(v.name) + '=' + esc(v.value); })
        .join('&')
        .value()
    ;
    strToSign += pvPairs;

    // console.log('StrToSign:', strToSign);

    return strToSign;
};

Amazon.prototype.signature = function(strToSign) {
    var self = this;

    // sign the request string
    var signature = crypto
        .createHmac('sha256', self.secretAccessKey())
        .update(strToSign)
        .digest('base64');

    // console.log('Signature :', signature);

    return signature;
};

Amazon.prototype.addSignature = function(options, signature) {
    options.params.push({ 'name' : 'Signature', 'value' : signature });
};

// --------------------------------------------------------------------------------------------------------------------
// exports

// constants
exports.US_EAST_1      = US_EAST_1;
exports.US_WEST_1      = US_WEST_1;
exports.EU_WEST_1      = EU_WEST_1;
exports.AP_SOUTHEAST_1 = AP_SOUTHEAST_1;
exports.AP_NORTHEAST_1 = AP_NORTHEAST_1;
exports.US_GOV_WEST_1  = US_GOV_WEST_1;
exports.SA_EAST_1      = SA_EAST_1;

// object constructor
exports.Amazon = Amazon;

// --------------------------------------------------------------------------------------------------------------------
