//-------------------------------------------------------------------------------------------------------------------
//
// swf.js - class for AWS Simple Workflow Service
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
var util = require('util');
var crypto = require('crypto');

// dependencies
var _ = require('underscore');
var xml2js = require('xml2js');
var dateFormat = require('dateformat');

// our own
var awssum = require('../awssum');
var amazon = require('./amazon');
var Sts = awssum.load('amazon/sts').Sts;
var operations = require('./swf-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'swf: ';
var debug = false;

// From: http://docs.amazonwebservices.com/amazonswf/latest/developerguide/swf-dg-using-swf-api.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "swf.us-east-1.amazonaws.com";
// no other endpoints exist for this service

// From: http://docs.amazonwebservices.com/amazonswf/latest/apireference/API_Operations.html
var version = '2012-01-25';
var signatureMethod = 'HmacSHA256';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Swf = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Swf.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    // create an STS client to use for getting the session tokens
    self._sts = new Sts(opts);

    return self;
};

// inherit from Amazon
util.inherits(Swf, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Swf.prototype.method = function() {
    return 'POST';
};

Swf.prototype.host = function() {
    return endPoint[this.region()];
};

Swf.prototype.version = function() {
    return version;
};

Swf.prototype.extractBody = function() {
    // SWF always returns JSON
    return 'json';
};

Swf.prototype.addCommonOptions = function(options, args) {
    var self = this;

    // add in the target
    options.headers['x-amz-target'] = 'SimpleWorkflowService.' + args.Target;
    // options.headers['content-encoding'] = 'amz-1.0'; // Do we need this? Can't see it in the docs? (also see below)
    options.headers['content-type'] = 'application/x-amz-json-1.0';

    // add the security token
    options.headers['x-amz-security-token'] = self._sessionToken;

    // date in RFC1123: Sun, 06 Nov 1994 08:49:37 GMT
    var dateHeader = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");

    // add the date header
    options.headers.Date = dateHeader;
    options.headers['x-amz-date'] = options.headers.Date;

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
};

// From: http://docs.amazonwebservices.com/amazonswf/latest/developerguide/HMACAuth-swf.html
Swf.prototype.strToSign = function(options) {
    var self = this;

    // This is a simple version to get working for now. Once working, we'll make it generic with DynamoDB.
    // See: https://forums.aws.amazon.com/thread.jspa?messageID=345540#345599
    var strToSign = '';
    strToSign += options.method.toUpperCase() + "\n";
    strToSign += "/\n";
    strToSign += "\n";
    // strToSign += "content-encoding:amz-1.0\n"; // Do we need this? Can't see it in the docs! (also see above)
    strToSign += 'host:' + options.host.toLowerCase() + "\n";
    strToSign += 'x-amz-date:' + options.headers.Date + "\n";
    strToSign += 'x-amz-security-token:' + options.headers['x-amz-security-token'] + "\n";
    strToSign += 'x-amz-target:' + options.headers['x-amz-target'] + "\n";
    strToSign += "\n";
    strToSign += options.body;

    if ( debug ) {
        console.log('-------------------------------------------------------------------------------');
        console.log('strToSign=' + strToSign + '(Ends)');
        console.log('-------------------------------------------------------------------------------');
    }

    return strToSign;
};

// From: http://docs.amazonwebservices.com/amazonswf/latest/developerguide/HMACAuth-swf.html
//
// Creates the signature for this request.
Swf.prototype.signature = function(strToSign) {
    var self = this;

    if ( debug ) {
        console.log('AccessKeyId            = ' + self.accessKeyId());
        console.log('SecretAccessKey        = ' + self.secretAccessKey());
        console.log('SessionToken           = ' + self._sessionToken);
        console.log('SessionTokenExpiration = ' + self._sessionTokenExpiration);
    }

    // firstly, get the SHA256 has of the strToSign
    var sha256 = crypto.createHash("sha256");
    var hash = sha256.update(strToSign).digest();

    // secondly, make the SHA256_HMAC of the hash from above
    var signature = crypto
        .createHmac('sha256', self.secretAccessKey())
        .update(hash)
        .digest('base64');

    if ( debug ) {
        console.log('signature              = ' + signature);
    }

    return signature;
};

// From: http://docs.amazonwebservices.com/amazonswf/latest/developerguide/UsingJSON-swf.html#HTTPHeader
//
// Adds the signature to the request.
Swf.prototype.addSignature = function(options, signature) {
    var self = this;

    options.headers['x-amzn-authorization'] = 'AWS3 AWSAccessKeyId=' + self.accessKeyId()
        + ', Algorithm=' + self.signatureMethod()
        // + ', SignedHeaders=host;x-amz-date;x-amz-security-token;x-amz-target' // optional
        + ', Signature=' + signature;

    if ( debug ) {
        console.log('Auth                   = ' + options.headers['x-amzn-authorization']);
        console.log('-------------------------------------------------------------------------------');
    }
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    // firstly, make the operation function so we can call it
    var mainOperation = awssum.makeOperation(operation);

    // console.log('Making the operation for ' + operationName);

    var doRequest = function(args, callback) {
        var self = this;
        // console.log('doRequest(): we already have a session token, so call the mainOperation');
        // console.log('self:', self);
        // console.log('args:', args);
        // console.log('callback:', callback);

        // do the request but check the return to see if we need a new session token
        mainOperation.apply(self, [ args, function(err, data) {
            if ( err ) {
                if ( err.StatusCode === 400 ) {
                    // this error wasn't a session token problem, so pass it back to the callback
                    callback(err, null);
                    return;
                }

                self._sts.GetSessionToken(function(err, data) {
                    if ( err ) {
                        // just pass this error back
                        callback(err, null);
                        return;
                    }

                    // set the new access key id, secret access key and session token
                    var credentials = data.Body.GetSessionTokenResponse.GetSessionTokenResult.Credentials;
                    self.setAccessKeyId(credentials.AccessKeyId);
                    self.setSecretAccessKey(credentials.SecretAccessKey);
                    self._sessionToken = credentials.SessionToken;
                    self._sessionTokenExpiration = new Date(credentials.Expiration);

                    // console.log('expiration=' + self._sessionTokenExpiration.toISOString());

                    // finally, do the operation again (no fallback this time)
                    mainOperation.apply(self, [args, callback]);
                });
                return;
            }

            // console.log('no error when calling the mainOperation, doing callback(null, data)');

            // no error, so just call the callback ok
            callback(null, data);
        }]);
    };

    // now create a function which calls the STS service and wraps the above mainOperation
    var wrapper = function(args, callback) {
        var self = this;

        // if args hasn't been given
        if ( callback === undefined ) {
            callback = args;
            args = {};
        }
        args = args || {};

        // console.log('Called ' + operationName);
        // console.log('args:', args);
        // console.log('callback:', callback);

        // if we have a session token already and it has more than a minute left, just do the request
        var currentDate = new Date();

        if ( !_.isUndefined(self._sessionToken) && self._sessionTokenExpiration.valueOf() < currentDate - 60 ) {
            // console.log('wrapper(): we already have a non-expired session token, so just do the request');
            doRequest.apply(self, [args, callback]);
            return;
        }

        // console.log('No session token, calling sts.GetSessionToken() first');

        // no session token, get one first, then call the request
        self._sts.GetSessionToken(function(err, data) {
            if ( err ) {
                // console.log('GetSessionToken(): got an error');
                // just pass this error back
                callback(err, null);
                return;
            }

            // set the new access key id, secret access key and session token
            var credentials = data.Body.GetSessionTokenResponse.GetSessionTokenResult.Credentials;
            // console.log('GetSessionToken() callback - credentials:', credentials);
            self.setAccessKeyId(credentials.AccessKeyId);
            self.setSecretAccessKey(credentials.SecretAccessKey);
            self._sessionToken = credentials.SessionToken;
            self._sessionTokenExpiration = new Date(credentials.Expiration);

            // console.log('expiration=' + self._sessionTokenExpiration.toISOString());

            // do the request
            doRequest.apply(self, [args, callback]);
        });
    };

    Swf.prototype[operationName] = wrapper;
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Swf = Swf;

// --------------------------------------------------------------------------------------------------------------------


// http://docs.amazonwebservices.com/amazonswf/latest/developerguide/HMACAuth-swf.html
