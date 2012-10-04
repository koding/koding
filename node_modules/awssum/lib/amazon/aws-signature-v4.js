// --------------------------------------------------------------------------------------------------------------------
//
// aws-signature-v4.js - helper functions for AWS Signature v4
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

function contentType() {
    return 'application/x-amz-json-1.1';
}

// From: http://docs.amazonwebservices.com/general/latest/gr/sigv4-create-string-to-sign.html
function strToSign(options, args) {
    var self = this;

    // From: http://docs.amazonwebservices.com/general/latest/gr/sigv4-create-canonical-request.html
    // CanonicalRequest =
    //     HTTPRequestMethod + '\n' +
    //     CanonicalURI + '\n' +
    //     CanonicalQueryString + '\n' +
    //     CanonicalHeaders + '\n' +
    //     SignedHeaders + '\n' +
    //     HexEncode(Hash(Payload))

    // firstly, create the canonical request
    var canonical = '';
    canonical += options.method + '\n';
    canonical += options.path + '\n';

    // add all the (sorted) params in
    var pvPairs = _(options.params)
        .chain()
        .sortBy(function(p) { return p.name; })
        .map(function(v, i) { return '' + esc(v.name) + '=' + esc(v.value); })
        .join('&')
        .value()
    ;
    canonical += pvPairs + '\n'; // ToDo: CanonicalQueryString
    canonical += 'host:' + self.host() + '\n';
    canonical += 'x-amz-date:' + options.headers.Date + '\n';
    if ( options.headers['x-amz-security-token'] ) {
        canonical += 'x-amz-security-token:' + options.headers['x-amz-security-token'] + '\n';
    }
    else {
        // canonical += 'x-amz-security-token:\n';
    }
    if ( options.headers['x-amz-glacier-version'] ) {
        canonical += 'x-amz-glacier-version:' + options.headers['x-amz-glacier-version'] + '\n';
    }
    if ( options.headers['x-amz-target'] ) {
        canonical += 'x-amz-target:' + options.headers['x-amz-target'] + '\n';
    }
    canonical += '\n';

    // signed headers
    var signedHeaders = 'host;x-amz-date';
    if ( options.headers['x-amz-glacier-version'] ) {
        signedHeaders += ';x-amz-glacier-version';
    }
    if ( options.headers['x-amz-security-token'] ) {
        signedHeaders += ';x-amz-security-token';
    }
    if ( options.headers['x-amz-target'] ) {
        signedHeaders += ';x-amz-target';
    }
    canonical += signedHeaders + '\n';

    // get the SHA256 hash of the strToSign
    var sha256 = crypto.createHash("sha256");
    var hex = sha256.update(options.body || '').digest('hex').toLowerCase();

    canonical += hex;

    if ( debug ) {
        console.log('===============================================================================');
        console.log('aws-signature-v4) Canonical :', canonical + '(Ends)');
        console.log('===============================================================================');
    }

    // now that we have the canonical request, we can create the strToSign

    var stringToSign = '';
    stringToSign += 'AWS4-HMAC-SHA256\n';
    stringToSign += options.headers.Date + '\n';
    stringToSign += options.headers.Date.substr(0, 8) + '/' + self.region() + '/' + self.scope() + '/aws4_request\n';
    stringToSign += crypto.createHash('sha256').update(canonical).digest('hex').toLowerCase();

    if ( debug ) {
        console.log('===============================================================================');
        console.log('aws-signature-v4) StringToSign :', stringToSign + '(Ends)');
        console.log('===============================================================================');
    }

    return stringToSign;
}

// From: http://docs.amazonwebservices.com/general/latest/gr/sigv4-calculate-signature.html
//
// Creates the signature for this request.
function signature(strToSign, options) {
    var self = this;

    var ymd = options.headers.Date.substr(0, 8);

    // Create our signing key!!! Crazy stuff.
    var signingKey = self.secretAccessKey();
    signingKey = crypto.createHmac('sha256', 'AWS4' + signingKey).update(ymd).digest('binary');
    signingKey = crypto.createHmac('sha256', signingKey).update(self.region()).digest('binary');
    signingKey = crypto.createHmac('sha256', signingKey).update(self.scope()).digest('binary');
    signingKey = crypto.createHmac('sha256', signingKey).update('aws4_request').digest('binary');

    // secondly, make the SHA256_HMAC of the hash from above
    return crypto
        .createHmac('sha256', signingKey)
        .update(strToSign)
        .digest('hex')
        .toLowerCase();
}

// From: http://docs.amazonwebservices.com/general/latest/gr/sigv4-signed-request-examples.html
//
// Adds the signature to the request.
function addSignature(options, signature) {
    var self = this;

    var signedHeaders = 'host;x-amz-date';
    if ( options.headers['x-amz-glacier-version'] ) {
        signedHeaders += ';x-amz-glacier-version';
    }
    if ( options.headers['x-amz-security-token'] ) {
        signedHeaders += ';x-amz-security-token';
    }
    if ( options.headers['x-amz-target'] ) {
        signedHeaders += ';x-amz-target';
    }

    options.headers['Authorization'] = 'AWS4-HMAC-SHA256'
        + ' Credential='
            + self.accessKeyId()
            + '/' + options.headers.Date.substr(0, 8)
            + '/' + self.region()
            + '/'
            + self.scope()
            + '/aws4_request'
        + ',SignedHeaders=' + signedHeaders
        + ',Signature=' + signature;

    if ( debug ) {
        console.log('Authorization=' + options.headers['Authorization']);
    }
}

// From: http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html
// From: http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/requestauth.html
// From: http://docs.amazonwebservices.com/storagegateway/latest/userguide/AWSStorageGatewaySigningRequests.html
// From: http://docs.amazonwebservices.com/amazonglacier/latest/dev/amazon-glacier-signing-requests.html
//
// This should work!
function addCommonOptions(options, args) {
    var self = this;

    // add in the target
    // Note: StorageGateway uses args.Target, yet CloudSearch uses args.Action!!!
    if ( self.needsTarget() ) {
        options.headers['x-amz-target'] = self.serviceName() + '_' + self.version() + '.' + (args.Target || args.Action);
    }

    // add the content-type (since some services are x-amz-json-1.0 and others x-amz-json-1.1)
    options.headers['content-type'] = self.contentType();

    // add in the date
    var now = new Date();
    var date = dateFormat(now, "UTC:yyyymmdd") + 'T' + dateFormat(now, "UTC:HHMMss") + 'Z';
    options.headers.Date = date;
    options.headers['x-amz-date'] = options.headers.Date;

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options, args);
    var signature = self.signature(strToSign, options);
    self.addSignature(options, signature);
}

// --------------------------------------------------------------------------------------------------------------------

exports.strToSign        = strToSign;
exports.signature        = signature;
exports.addSignature     = addSignature;
exports.addCommonOptions = addCommonOptions;
exports.contentType      = contentType;

// --------------------------------------------------------------------------------------------------------------------
