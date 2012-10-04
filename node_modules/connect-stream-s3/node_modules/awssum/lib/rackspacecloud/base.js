// --------------------------------------------------------------------------------------------------------------------
//
// rackspacecloud/base.js - the base class for all RackspaceCloud Services
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
// requires

var util = require("util");
var crypto = require('crypto');
var https = require('https');

// dependencies
var _ = require('underscore');

// our own library
var awssum = require ("../awssum");

// --------------------------------------------------------------------------------------------------------------------
// constants

var MARK = 'rackspacecloud: ';

var UK = 'UK';
var US = 'US';

var Region = {
    UK : true,
    US : true,
};

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Base = function(username, apiKey, region) {
    var self = this;

    // call the superclass for initialisation
    Base.super_.call(this);

    // check that we have each of these values
    if ( ! username ) {
        throw MARK + 'username is required';
    }
    if ( ! apiKey ) {
        throw MARK + 'apiKey is required';
    }
    if ( ! region ) {
        throw MARK + 'region is required';
    }

    // allow access to (but not change) these variables
    self.username = function() { return username; };
    self.apiKey   = function() { return apiKey;   };
    self.region   = function() { return region;   };

    return self;
};

// inherit from AwsSum
util.inherits(Base, awssum.AwsSum);

// --------------------------------------------------------------------------------------------------------------------
// utility/helper functions

// none

// --------------------------------------------------------------------------------------------------------------------
// functions to be overriden by inheriting class

// none

// --------------------------------------------------------------------------------------------------------------------
// exports

// constants
exports.US = US;
exports.UK = UK;
exports.Region = Region;

// object constructor
exports.Base = Base;

// --------------------------------------------------------------------------------------------------------------------
