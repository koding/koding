// --------------------------------------------------------------------------------------------------------------------
//
// twitter/twitter.js - class for the Twitter API
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

// dependencies
var _ = require('underscore');

// our own
var awssum = require('../awssum');
var oauth = awssum.load('oauth');
var operations = require('./twitter-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'twitter: ';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Twitter = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Twitter.super_.call(this, opts);

    return self;
};

// inherit from OAuth
util.inherits(Twitter, oauth.OAuth);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Twitter.prototype.host = function() {
    return 'api.twitter.com';
};

Twitter.prototype.version = function() {
    return '1';
};

Twitter.prototype.extractBody = function() {
    return 'json';
};

Twitter.prototype.requestTokenHost = function() {
    return 'api.twitter.com';
};
Twitter.prototype.requestTokenPath = function() {
    return '/oauth/request_token';
};
Twitter.prototype.authorizeHost = function() {
    return 'api.twitter.com';
};
Twitter.prototype.authorizePath = function() {
    return '/oauth/authorize';
};
Twitter.prototype.accessTokenHost = function() {
    return 'api.twitter.com';
};
Twitter.prototype.accessTokenPath = function() {
    return '/oauth/access_token';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Twitter.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Twitter = Twitter;

// --------------------------------------------------------------------------------------------------------------------
