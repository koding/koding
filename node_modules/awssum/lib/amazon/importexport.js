// --------------------------------------------------------------------------------------------------------------------
//
// importexport.js - class for AWS Import/Export
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
var amazon = require('./amazon');
var operations = require('./importexport-config');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'importexport: ';

var version = '2010-06-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var ImportExport = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // call the superclass for initialisation
    ImportExport.super_.call(this, opts);

    return self;
};

// inherit from Amazon
util.inherits(ImportExport, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

ImportExport.prototype.host = function() {
    return 'importexport.amazonaws.com';
};

ImportExport.prototype.version = function() {
    return version;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    ImportExport.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.ImportExport = ImportExport;

// --------------------------------------------------------------------------------------------------------------------
