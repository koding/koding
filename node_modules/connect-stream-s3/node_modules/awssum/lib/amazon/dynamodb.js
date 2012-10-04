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

// From: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/HMACAuth.html
//
// Returns a strToSign for this request.
DynamoDB.prototype.strToSign = function(options, args) {
    var self = this;

    // firstly, get the following headers
    var headers = {};
    headers.host = self.host();
    if ( !_.isUndefined( options.headers['x-amz-security-token'] ) ) {
        headers['x-amz-security-token'] = options.headers['x-amz-security-token'];
    }
    headers['x-amz-target'] = options.headers['x-amz-target'];

    // create the canonicalizedHeaders
    var canonicalizedHeaders = '';
    var headerNames = _.keys(headers).sort();
    _.each(headerNames, function(hdrName, i) {
        canonicalizedHeaders += hdrName + ':' + headers[hdrName] + '\n';
    });

    var canonicalHeaders = headerNames.map(function(key) {
        return util.format("%s:%s\n", key.trim().toLowerCase(), headers[key].trim());
    }).sort().join('');

    // From: https://forums.aws.amazon.com/thread.jspa?threadID=85891
    var strToSign = '';
    strToSign += options.method + "\n";
    strToSign += "/\n";
    strToSign += "\n";
    strToSign += 'host:' + headers.host + "\n";
    strToSign += 'x-amz-date:' + options.headers.Date + "\n";
    strToSign += 'x-amz-security-token:' + options.headers['x-amz-security-token'] + "\n";
    strToSign += 'x-amz-target:' + options.headers['x-amz-target'] + "\n";
    strToSign += "\n";
    strToSign += options.body;

    // console.log('===============================================================================');
    // console.log('3) StrToSign :', strToSign + '(Ends)');
    // console.log('===============================================================================');

    return strToSign;
};

// From: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/HMACAuth.html
//
// Creates the signature for this request.
DynamoDB.prototype.signature = function(strToSign) {
    var self = this;

    // console.log('AccessKeyId = ' + self.accessKeyId());
    // console.log('SecretAccessKey = ' + self.secretAccessKey());
    // console.log('SessionToken = ' + self._sessionToken);
    // console.log('SessionTokenExpiration = ' + self._sessionTokenExpiration);

    // firstly, get the SHA256 has of the strToSign
    var sha256 = crypto.createHash("sha256");
    var hash = sha256.update(strToSign).digest();
    // console.log('*** HASH = ' + hash);

    // secondly, make the SHA256_HMAC of the hash from above
    var signature = crypto
        .createHmac('sha256', self.secretAccessKey())
        .update(hash)
        .digest('base64');

    return signature;
};

// From: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/HMACAuth.html
//
// Adds the signature to the request.
DynamoDB.prototype.addSignature = function(options, signature) {
    var self = this;
    // console.log('addSignature(): signatureMethod = ' + self.signatureMethod());
    options.headers['x-amzn-authorization'] = 'AWS3 AWSAccessKeyId=' + self.accessKeyId()
        + ',Algorithm=' + self.signatureMethod()
        + ',SignedHeaders=host;x-amz-date;x-amz-security-token;x-amz-target'
        + ',Signature=' + signature;

    // console.log('Auth=' + options.headers['x-amzn-authorization']);
};

// From: http://docs.amazonwebservices.com/DynamoDB/latest/APIReference/Headers.html
//
// Adds the common headers to this request.
DynamoDB.prototype.addCommonOptions = function(options, args) {
    var self = this;

    // add in the target
    options.headers['x-amz-target'] = 'DynamoDB_' + self.version() + '.' + args.Target;

    // add the content-type
    options.headers['content-type'] = 'application/x-amz-json-1.0';

    // add the security token
    options.headers['x-amz-security-token'] = self._sessionToken;

    // add in the date
    var date = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");
    options.headers.Date = date;
    options.headers['x-amz-date'] = options.headers.Date;

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options, args);
    var signature = self.signature(strToSign);
    self.addSignature(options, signature);
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

    DynamoDB.prototype[operationName] = wrapper;
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.DynamoDB = DynamoDB;

// --------------------------------------------------------------------------------------------------------------------
