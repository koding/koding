// --------------------------------------------------------------------------------------------------------------------
//
// xero/xero.js - class for the Xero API
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
var operations = require('./xero-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'xero: ';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Xero = function(opts) {
    var self = this;

    // call the superclass for initialisation
    Xero.super_.call(this, opts);

    return self;
};

// inherit from OAuth
util.inherits(Xero, oauth.OAuth);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Xero.prototype.host = function() {
    return 'api.xero.com';
};

Xero.prototype.version = function() {
    return '2.0';
};

Xero.prototype.addCommonOptions = function(options, args) {
    // firstly, call the OAuth addCommonHeaders() function
    Xero.super_.prototype.addCommonOptions.call(this, options, args);

    // now tell Xero that we want JSON, not XML
    options.headers.Accept = 'application/json';
};

Xero.prototype.extractBody = function() {
    return 'json';
};

Xero.prototype.requestTokenHost = function() {
    return 'api.xero.com';
};
Xero.prototype.requestTokenPath = function() {
    return '/oauth/RequestToken';
};
Xero.prototype.authorizeHost = function() {
    return 'api.xero.com';
};
Xero.prototype.authorizePath = function() {
    return '/oauth/Authorize';
};
Xero.prototype.accessTokenHost = function() {
    return 'api.xero.com';
};
Xero.prototype.accessTokenPath = function() {
    return '/oauth/AccessToken';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Xero.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Xero = Xero;

// --------------------------------------------------------------------------------------------------------------------
