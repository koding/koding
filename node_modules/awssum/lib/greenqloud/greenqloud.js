// --------------------------------------------------------------------------------------------------------------------
//
// greenqloud.js - the base class for all GreenQloud
//
// Copyright (c) 2011-2012 AppsAttic Ltd - http://www.appsattic.com/
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

var MARK = 'greenqloud: ';

// regions
var IS_1 = 'is-1';

var Region = {
    IS_1 : true,
};

// create our XML parser
var parser = new xml2js.Parser({ normalize : false, trim : false, explicitRoot : true });

// --------------------------------------------------------------------------------------------------------------------
// constructor

var GreenQloud = function(opts) {
    var self = this;
    var accessKeyId, secretAccessKey, awsAccountId, region;

    // call the superclass for initialisation
    GreenQloud.super_.call(this, opts);

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
util.inherits(GreenQloud, awssum.AwsSum);

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting class

// see ../awssum.js for more details

GreenQloud.prototype.extractBody = function() {
    return 'xml';
};

GreenQloud.prototype.addCommonOptions = function(options) {
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
// functions to be overriden by inheriting (GreenQloud) class

// function version()              -> string (the version of this service)
// function signatureVersion()     -> string (the signature version used)
// function signatureMethod()      -> string (the signature method used)
// function strToSign(options)     -> string (the string that needs to be signed)
// function signature(strToSign)   -> string (the signature itself)
// function addSignature(options, signature) -> side effect, adds the signature to the 'options'

// GreenQloud.prototype.version // no default

GreenQloud.prototype.signatureVersion = function() {
    return 2;
};

GreenQloud.prototype.signatureMethod = function() {
    return 'HmacSHA256';
};

GreenQloud.prototype.strToSign = function(options) {
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

GreenQloud.prototype.signature = function(strToSign) {
    var self = this;

    // sign the request string
    var signature = crypto
        .createHmac('sha256', self.secretAccessKey())
        .update(strToSign)
        .digest('base64');

    // console.log('Signature :', signature);

    return signature;
};

GreenQloud.prototype.addSignature = function(options, signature) {
    options.params.push({ 'name' : 'Signature', 'value' : signature });
};

// --------------------------------------------------------------------------------------------------------------------
// exports

// constants
exports.IS_1 = IS_1;

// object constructor
exports.GreenQloud = GreenQloud;

// --------------------------------------------------------------------------------------------------------------------
