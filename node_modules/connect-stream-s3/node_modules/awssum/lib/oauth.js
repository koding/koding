// --------------------------------------------------------------------------------------------------------------------
//
// oauth.js - the base class for all Oauth 1.0a web services in node-awssum
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
var passgen = require('passgen');

// our own
var awssum = require('./awssum');
var esc = require('../lib/esc.js');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'oauth: ';

var debug = false;

// --------------------------------------------------------------------------------------------------------------------
// constructor

var OAuth = function(opts) {
    var self = this;
    var consumerKey;
    var consumerSecret;
    var token;
    var tokenSecret;

    // call the superclass for initialisation
    OAuth.super_.call(this);

    // check that we have each of these values
    if ( ! opts.consumerKey ) {
        throw MARK + 'consumerKey is required';
    }
    if ( ! opts.consumerSecret ) {
        throw MARK + 'consumerSecret is required';
    }

    // allow setting of these variables
    self.setToken = function(str) {
        if ( ! str ) {
            throw MARK + 'token is required when setting it';
        }
        token = str;
    };
    self.setTokenSecret = function(str) {
        if ( ! str ) {
            throw MARK + 'tokenSecret is required when setting it';
        }
        tokenSecret = str;
    };

    // allow access to all of these things
    consumerKey         = opts.consumerKey;
    consumerSecret      = opts.consumerSecret;
    self.consumerKey    = function() { return consumerKey;    };
    self.consumerSecret = function() { return consumerSecret; };
    self.token          = function() { return token;           };
    self.tokenSecret    = function() { return tokenSecret;     };

    return self;
};

// inherit from AwsSum
util.inherits(OAuth, awssum.AwsSum);

// --------------------------------------------------------------------------------------------------------------------
// extra request headers

function extrasContentLength(options, args) {
    var self = this;

    // add the Content-Length header we need
    if ( args.ContentLength ) {
        options.headers['Content-Length'] = args.ContentLength;
        return;
    }
    if ( options.body ) {
        // ToDo: switch this to do the same buffer thing as nfriedly
        options.headers['Content-Length'] = options.body.length;
        return;
    }
    // else, it must be zero
    options.headers['Content-Length'] = 0;
}

// --------------------------------------------------------------------------------------------------------------------
// functions common between all OAuth services

var RequestToken = {
    // request
    'method'      : 'POST',
    'host'        : function() { return this.requestTokenHost(); },
    'path'        : function() { return this.requestTokenPath(); },
    'args'        : {
        'OAuthCallback' : {
            required : true,
            name     : 'oauth_callback',
            type     : 'param',
        },
    },
    'addExtras' : extrasContentLength, // required for Tumblr, Twitter is fine without it
    'authentication' : false,
    // response
    extractBody : 'application/x-www-form-urlencoded', // may be overriden by inheriting class, so make sure this stays
    extractBodyWhenError : 'blob',
};

var GetToken = {
    // request
    'method'      : 'POST',
    'host'        : function() { return this.accessTokenHost(); },
    'path'        : function() { return this.accessTokenPath(); },
    'args'        : {
        'OAuthVerifier' : {
            required : true,
            name     : 'oauth_verifier',
            type     : 'param',
        },
    },
    'addExtras' : extrasContentLength, // required for Tumblr, Twitter is fine without it
    'authentication' : false,
    // response
    // may be overriden by inheriting class, so make sure this stays
    'extractBody' : 'application/x-www-form-urlencoded',
};

OAuth.prototype.RequestToken = awssum.makeOperation(RequestToken);
OAuth.prototype.GetToken = awssum.makeOperation(GetToken);

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting class

// see ./awssum.js, plus additional methods such as:
//
// * requestTokenHost
// * requestTokenPath
// * authorizeHost
// * authorizePath
// * accessTokenHost
// * accessTokenPath

OAuth.prototype.protocol = function() {
    return 'https';
};

OAuth.prototype.oauthSignatureType = function() {
    // From: http://tools.ietf.org/html/rfc5849#section-3.5
    // could be 'header', 'body' or 'param'
    return 'header';
};

OAuth.prototype.addCommonOptions = function(options, args) {
    var self = this;

    // get the date in epoch
    var timestamp = parseInt((new Date()).valueOf()/1000, 10);
    var nonce = passgen.create(12);

    // add in the common params for OAuth 1.0a

    // Common oauth params:
    // * oauth_consumer_key
    // * oauth_version
    // * oauth_timestamp
    // * oauth_nonce
    // * oauth_signature_method
    // * oauth_signature
    //
    // For RequestToken:
    // * oauth_token
    // * oauth_callback
    //
    // For GetToken:
    // * oauth_verifier (from the user or the redirect from the OAuth provide)
    // * oauth_token (from RequestToken)
    //
    // For an authenticated operation:
    // * oauth_token (from GetToken)
    // * oauth_token_secret (from GetToken)

    // oauth params (needed for signing) and all the incoming params
    var oauthParams = [];
    oauthParams.push({ 'name' : 'oauth_consumer_key',     'value' : self.consumerKey() });
    oauthParams.push({ 'name' : 'oauth_version',          'value' : '1.0'              });
    oauthParams.push({ 'name' : 'oauth_timestamp',        'value' : timestamp          });
    oauthParams.push({ 'name' : 'oauth_nonce',            'value' : nonce              });
    oauthParams.push({ 'name' : 'oauth_signature_method', 'value' : 'HMAC-SHA1'        });
    if ( self.token() ) {
        oauthParams.push({ 'name' : 'oauth_token', 'value' : self.token() });
    }
    options.params.forEach(function(v, i) {
        oauthParams.push(v);
    });

    // sign ALL of the params, including those passed in and those for OAuth
    if ( self.oauthSignatureType() === 'param' ) {
        options.params.push({ 'name' : 'oauth_consumer_key',     'value' : self.consumerKey() });
        options.params.push({ 'name' : 'oauth_version',          'value' : '1.0'              });
        options.params.push({ 'name' : 'oauth_timestamp',        'value' : timestamp          });
        options.params.push({ 'name' : 'oauth_nonce',            'value' : nonce              });
        options.params.push({ 'name' : 'oauth_signature_method', 'value' : 'HMAC-SHA1'        });
        if ( self.token() ) {
            options.params.push({ 'name' : 'oauth_token', 'value' : self.token() });
        }
    }
    else if ( self.oauthSignatureType() === 'header' ) {
        // nothing to do
    }

    // make the signature
    var strToSign = esc(options.method.toUpperCase()) + '&' + esc(self.protocol() + '://' + options.host + options.path);
    var pairs = _(oauthParams)
        .chain()
        .sortBy(function(p) { return p.name; })
        .map(function(v, i) { return '' + v.name + '=' + esc(v.value); })
        .join('&')
        .value()
    ;
    strToSign += '&' + esc(pairs);

    // sign the request string
    var signatureKey = esc(self.consumerSecret()) + '&';
    if ( self.tokenSecret() ) {
        signatureKey += esc(self.tokenSecret());
    }

    var signature = crypto
        .createHmac('sha1', signatureKey)
        .update(strToSign)
        .digest('base64');

    // add the 'Authorization' header
    if ( self.oauthSignatureType() === 'header' ) {
        options.headers.Authorization = 'OAuth ' + [
            'oauth_version="1.0"',
            'oauth_consumer_key="' + esc(self.consumerKey()) + '"',
            'oauth_timestamp="' + esc(timestamp)  + '"',
            'oauth_nonce="' + nonce + '"',
            'oauth_signature_method="HMAC-SHA1"',
            'oauth_signature="' + esc(signature) + '"',
        ].join(', ');
        if ( self.token() ) {
            options.headers.Authorization += ', oauth_token="' + self.token() + '"';
        }
    }
    else if ( self.oauthSignatureType() === 'param' ) {
        // add the oauth_signature onto the params
        options.params.push({ 'name' : 'oauth_signature', 'value' : signature });
    }

    if ( debug ) {
        console.log('-------------------------------------------------------------------------------');
        console.log('OAuth Signature:');
        console.log('- signatureKey   : ', signatureKey);
        console.log('- strTosign      : ', strToSign);
        console.log('- signature      : ', signature);
        console.log('-------------------------------------------------------------------------------');
    }
};

OAuth.prototype.extractBody = function() {
    // most OAuth things return an encoded form
    return 'application/x-www-form-urlencoded';
};

// --------------------------------------------------------------------------------------------------------------------
// exports

// object constructor
exports.OAuth = OAuth;

// --------------------------------------------------------------------------------------------------------------------
