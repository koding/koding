// --------------------------------------------------------------------------------------------------------------------
//
// imd.js - class for AWS Instance MetaData
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
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
// var amazon = require('./amazon');
var operations = require('./imd-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'imd: ';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Imd = function(opts) {
    var self = this;
    opts = opts || {};

    // call the superclass for initialisation
    Imd.super_.call(this, opts);

    return self;
};

// inherit from AwsSum
util.inherits(Imd, awssum.AwsSum);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

Imd.prototype.protocol = function() {
    return 'http';
};

Imd.prototype.host = function() {
    return '169.254.169.254';
};

Imd.prototype.extractBodyWhenError = function(options) {
    return 'xml';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    Imd.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Imd = Imd;

// --------------------------------------------------------------------------------------------------------------------
