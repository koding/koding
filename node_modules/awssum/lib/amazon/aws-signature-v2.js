// --------------------------------------------------------------------------------------------------------------------
//
// aws-signature-v2.js - helper functions for AWS Signature v2
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
// requires

// built-ins
var crypto = require('crypto');

// dependencies
var _ = require('underscore');
var dateFormat = require('dateformat');
var esc = require('../esc');

// --------------------------------------------------------------------------------------------------------------------
// constants

var debug = false;

// --------------------------------------------------------------------------------------------------------------------

// Some example services and examples:
//
// * https://payments.amazon.com/sdui/sdui/helpTab/Amazon-Flexible-Payments-Service/Technical-Resources/Signature-V2
// * http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/Query_QueryAuth.html
// * http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/using-query-api.html

function signatureVersion() {
    return 2;
}

function signatureMethod() {
    return 'HmacSHA256';
}

// Creates the strToSign for this request.
function strToSign(options, args) {
    var self = this;

    // create the strToSign for this request
    var toSign = options.method + "\n" + options.host.toLowerCase() + "\n" + options.path + "\n";

    // now add on all of the params (after being sorted)
    var pvPairs = _(options.params)
        .chain()
        .sortBy(function(p) { return p.name; })
        .map(function(v, i) { return '' + esc(v.name) + '=' + esc(v.value); })
        .join('&')
        .value()
    ;
    toSign += pvPairs;

    // console.log('toSign:', toSign);

    return toSign;
}

// Creates the signature for this request.
function signature(strToSign, options) {
    var self = this;

    // sign the request string
    var sig = crypto
        .createHmac('sha256', self.secretAccessKey())
        .update(strToSign)
        .digest('base64');

    // console.log('Signature :', sig);

    return sig;
}

// Adds the signature to the request.
function addSignature(options, signature) {
    var self = this;
    options.params.push({ 'name' : 'Signature', 'value' : signature });
}

// Called by AwsSum, and this calls the rest of the Amazon Signature things (above).
function addCommonOptions(options, args) {
    var self = this;

    // get the date in UTC : %Y-%m-%dT%H:%M:%SZ
    var date = (new Date()).toISOString();

    // add in the common params
    options.params.push({ 'name' : 'AWSAccessKeyId', 'value' : self.accessKeyId() });
    if( self.token() ) {
        options.params.push({ 'name' : 'SecurityToken', 'value' : self.token() });
    }
    options.params.push({ 'name' : 'SignatureVersion', 'value' : self.signatureVersion() });
    options.params.push({ 'name' : 'SignatureMethod', 'value' : self.signatureMethod() });
    options.params.push({ 'name' : 'Timestamp', 'value' : date });
    options.params.push({ 'name' : 'Version', 'value' : self.version() });

    // make the strToSign, create the signature and sign it
    var toSign = self.strToSign(options);
    var signature = self.signature(toSign);
    self.addSignature(options, signature);
}

// --------------------------------------------------------------------------------------------------------------------

exports.signatureVersion = signatureVersion;
exports.signatureMethod  = signatureMethod;
exports.strToSign        = strToSign;
exports.signature        = signature;
exports.addSignature     = addSignature;
exports.addCommonOptions = addCommonOptions;

// --------------------------------------------------------------------------------------------------------------------
