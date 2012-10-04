// --------------------------------------------------------------------------------------------------------------------
//
// yahoo/contacts.js - class for the Yahoo! Contacts API
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
var Yahoo = awssum.load('yahoo/yahoo').Yahoo;
var operations = require('./contacts-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'yahoo/contacts: ';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Contacts = function(opts) {
    var self = this;
    var yahooGuid;

    // call the superclass for initialisation
    Contacts.super_.call(this, opts);

    // check we have a yahooGuid
    if ( ! opts.yahooGuid ) {
        throw MARK + "provide a 'yahooGuid'";
    }
    self.setYahooGuid(opts.yahooGuid);

    // getters and setters
    self.setYahooGuid = function(newStr) { yahooGuid = newStr; };
    self.yahooGuid = function() { return yahooGuid; };

    return self;
};

// inherit from Yahoo! (and therefore OAuth)
util.inherits(Contacts, Yahoo);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Contacts.prototype.protocol = function() {
    return 'http';
};

Contacts.prototype.host = function() {
    return 'social.yahooapis.com';
};

Contacts.prototype.version = function() {
    return 'v1';
};

Contacts.prototype.addCommonOptions = function(options, args) {
    // firstly, call the OAuth addCommonHeaders() function
    Contacts.super_.prototype.addCommonOptions.call(this, options, args);

    // now tell Yahoo! that we want JSON, not XML
    options.headers.Accept = 'application/json';
};

Contacts.prototype.extractBody = function() {
    return 'json';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Contacts.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Contacts = Contacts;

// --------------------------------------------------------------------------------------------------------------------
