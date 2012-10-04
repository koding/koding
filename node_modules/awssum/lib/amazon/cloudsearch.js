// --------------------------------------------------------------------------------------------------------------------
//
// cloudsearch.js - class for AWS CloudSearch
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
var operations = require('./cloudsearch-config');
var awsSignatureV4 = require('./aws-signature-v4');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'cloudsearch: ';

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
var endPoint = {};
endPoint[amazon.US_EAST_1]      = "cloudsearch.us-east-1.amazonaws.com";
// endPoint[amazon.US_WEST_1]      = "";
// endPoint[amazon.US_WEST_2]      = "";
// endPoint[amazon.EU_WEST_1]      = "";
// endPoint[amazon.AP_SOUTHEAST_1] = "";
// endPoint[amazon.AP_NORTHEAST_1] = "";
// endPoint[amazon.SA_EAST_1]      = "";
// endPoint[amazon.US_GOV_WEST_1]  = "";

var version = '2011-02-01';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var CloudSearch = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // call the superclass for initialisation
    CloudSearch.super_.call(this, opts);

    return self;
};

// inherit from Amazon
util.inherits(CloudSearch, amazon.Amazon);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from amazon.js

CloudSearch.prototype.scope = function() {
    return 'cloudsearch';
};

CloudSearch.prototype.serviceName = function() {
    return 'CloudSearch';
};

CloudSearch.prototype.needsTarget = function() {
    return true;
};

CloudSearch.prototype.method = function() {
    return 'POST';
};

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
CloudSearch.prototype.host = function(args) {
    return 'cloudsearch.us-east-1.amazonaws.com';
};

CloudSearch.prototype.version = function() {
    return version;
};

// This service uses the AWS Signature v4.
// Hopefully, it fulfills : http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/requestauth.html
CloudSearch.prototype.strToSign        = awsSignatureV4.strToSign;
CloudSearch.prototype.signature        = awsSignatureV4.signature;
CloudSearch.prototype.addSignature     = awsSignatureV4.addSignature;
CloudSearch.prototype.addCommonOptions = awsSignatureV4.addCommonOptions;
CloudSearch.prototype.contentType      = awsSignatureV4.contentType;

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    CloudSearch.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// now create the object for the DocumentService

var DocumentService = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // check that we have each of these values
    if ( ! opts.domainName ) {
        throw MARK + 'domainName is required';
    }
    if ( ! opts.domainId ) {
        throw MARK + 'domainId is required';
    }

    // call the superclass for initialisation
    DocumentService.super_.call(this, opts);

    // set the local vars so the functions below can close over them
    var domainName = opts.domainName;
    var domainId   = opts.domainId;
    var region     = opts.region;
    self.domainName = function() { return domainName; };
    self.domainId   = function() { return domainId;   };
    self.region     = function() { return region;     };

    return self;
};

// inherit from AwsSum
util.inherits(DocumentService, awssum.AwsSum);

DocumentService.prototype.version = function() {
    return version;
};

DocumentService.prototype.method = function() {
    return 'POST';
};

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
DocumentService.prototype.host = function(args) {
    return 'doc-' +  this.domainName() + '-' + this.domainId() + '.' + this.region() + '.cloudsearch.amazonaws.com';
};

DocumentService.prototype.path = function() {
    return '/' + this.version() + '/documents/batch';
};

DocumentService.prototype.addCommonOptions = function(options, args) {
    options.headers['content-type'] = 'application/json';
};

// DocumentService.prototype.extractBody = function() {
//     return 'xml';
// };

// From: http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/DocSvcAPI.html
//
// * http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/DocumentsBatch.html

var docOperations = {
    DocumentsBatch : {
        'args' : {
            Docs : {
                required : true,
                type     : 'special',
            },
        },
        'body' : function(options, args) {
            return JSON.stringify(args.Docs);
        },
    },
};

_.each(docOperations, function(operation, operationName) {
    DocumentService.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// SearchService

var SearchService = function(opts) {
    var self = this;

    // we only have one region for this service, so default it here
    opts.region = amazon.US_EAST_1;

    // check that we have each of these values
    if ( ! opts.domainName ) {
        throw MARK + 'domainName is required';
    }
    if ( ! opts.domainId ) {
        throw MARK + 'domainId is required';
    }

    // call the superclass for initialisation
    SearchService.super_.call(this, opts);

    // set the local vars so the functions below can close over them
    var domainName = opts.domainName;
    var domainId   = opts.domainId;
    var region     = opts.region;
    self.domainName = function() { return domainName; };
    self.domainId   = function() { return domainId  ; };
    self.region     = function() { return region;     };

    return self;
};

// inherit from AwsSum
util.inherits(SearchService, awssum.AwsSum);

SearchService.prototype.version = function() {
    return version;
};

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html
SearchService.prototype.host = function(args) {
    return 'search-' +  this.domainName() + '-' + this.domainId() + '.' + this.region() + '.cloudsearch.amazonaws.com';
};

SearchService.prototype.path = function() {
    return '/' + this.version() + '/search';
};

SearchService.prototype.extractBody = function() {
    return 'json';
};

// From: http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/SearchAPI.html
//
// * http://docs.amazonwebservices.com/cloudsearch/latest/developerguide/Search.html

var searchOperations = {

    Search : {
        // request
        args : {
            'q' : {
                required : false,
                type     : 'param'
            },
            'bq' : {
                required : false,
                type     : 'param',
            },
            'facet' : {
                required : false,
                type     : 'param',
            },
            'fields' : {
                required : false,
                type     : 'special',
            },
            'rank' : {
                required : false,
                type     : 'param',
            },
            'results-type' : {
                required : false,
                type     : 'param',
            },
            'return-fields' : {
                required : false,
                type     : 'param',
            },
            'size' : {
                required : false,
                type     : 'param',
            },
            'start' : {
                required : false,
                type     : 'param',
            },
            // 't' : {
            //     required : false,
            //     type     : 'param',
            // },
        },
        addExtras : function(options, args) {
            // process the 'facets'
            if ( !args.field ) {
                return;
            }

            var fields = Object.keys(args.field);
            fields.forEach(function(field, i) {
                var name;
                if ( args.field[field].constraints ) {
                    name = 'facet-' + field + '-constraints';
                    options.params.push({ 'name' : name, 'value' : args.field[field].constraints });
                }
                if ( args.field[field].sort ) {
                    name = 'facet-' + field + '-sort';
                    options.params.push({ 'name' : name, 'value' : args.field[field].sort });
                }
                if ( args.field[field]['top-n'] ) {
                    name = 'facet-' + field + '-top-n';
                    options.params.push({ 'name' : name, 'value' : args.field[field]['top-n'] });
                }
            });
        },
    },
};

_.each(searchOperations, function(operation, operationName) {
    SearchService.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.CloudSearch     = CloudSearch;
exports.DocumentService = DocumentService;
exports.SearchService   = SearchService;

// --------------------------------------------------------------------------------------------------------------------
