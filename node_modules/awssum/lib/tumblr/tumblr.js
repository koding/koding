// --------------------------------------------------------------------------------------------------------------------
//
// tumblr/tumblr.js - class for the Tumblr API
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
var https = require('https');
var http = require('http');

// dependencies
var _ = require('underscore');
var xml2js = require('xml2js');
var dateFormat = require('dateformat');
var XML = require('xml');
var data2xml = require('data2xml');

// our own
var awssum = require('../awssum');
var oauth = awssum.load('oauth');
var operations = require('./tumblr-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'tumblr: ';

// create our XML parser
var parser = new xml2js.Parser({ normalize : false, trim : false, explicitRoot : true });

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Tumblr = function(oauthConsumerKey, oauthConsumerSecret) {
    var self = this;

    // call the superclass for initialisation
    Tumblr.super_.call(this, oauthConsumerKey, oauthConsumerSecret);

    return self;
};

// inherit from OAuth
util.inherits(Tumblr, oauth.OAuth);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js

Tumblr.prototype.host = function() {
    return 'api.tumblr.com';
};

Tumblr.prototype.version = function() {
    return 'v2';
};

Tumblr.prototype.requestTokenHost = function() {
    return 'www.tumblr.com';
};
Tumblr.prototype.requestTokenPath = function() {
    return '/oauth/request_token';
};
Tumblr.prototype.authorizeHost = function() {
    return 'www.tumblr.com';
};
Tumblr.prototype.authorizePath = function() {
    return '/oauth/authorize';
};
Tumblr.prototype.accessTokenHost = function() {
    return 'www.tumblr.com';
};
Tumblr.prototype.accessTokenPath = function() {
    return '/oauth/access_token';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Tumblr.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Tumblr = Tumblr;

// --------------------------------------------------------------------------------------------------------------------
