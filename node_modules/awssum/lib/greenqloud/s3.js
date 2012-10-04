// --------------------------------------------------------------------------------------------------------------------
//
// s3.js - class for GreenQloud Simple Storage Service
//
// Copyright (c) 2011-2012 AppsAttic Ltd - http://www.appsattic.com/
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
var xml2js = require('xml2js');
var dateFormat = require('dateformat');
var XML = require('xml');
var data2xml = require('data2xml');

// our own
var awssum = require('../awssum');
var greenqloud = require('./greenqloud');
var operations = require('../amazon/s3-config');
var esc = require('../esc');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 's3: ';

// From: http://support.greenqloud.com/entries/20020852-using-the-api
var endPoint = {};
endPoint[greenqloud.IS_1] = "s.greenqloud.com";

// From: http://docs.amazonwebservices.com/general/latest/gr/rande.html#s3_region
var locationConstraint = {};
locationConstraint[greenqloud.IS_1] = "";

var version = '2006-03-01';

// List from: http://docs.amazonwebservices.com/AmazonS3/2006-03-01/dev/RESTAuthentication.html
var validSubresource = {
    acl            : true,
    'delete'       : true,
    lifecycle      : true,
    location       : true,
    logging        : true,
    notification   : true,
    partNumber     : true,
    policy         : true,
    requestPayment : true,
    torrent        : true,
    uploadId       : true,
    uploads        : true,
    versionId      : true,
    versioning     : true,
    versions       : true,
    website        : true,
    // For http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
    'response-content-type'        : true,
    'response-content-language'    : true,
    'response-expires'             : true,
    'response-cache-control'       : true,
    'response-content-disposition' : true,
    'response-content-encoding'    : true,
};

// create our XML parser
var parser = new xml2js.Parser({ normalize : false, trim : false, explicitRoot : true });

// --------------------------------------------------------------------------------------------------------------------
// constructor

var S3 = function(opts) {
    var self = this;

    // call the superclass for initialisation
    S3.super_.call(this, opts);

    // check the region is valid
    if ( ! endPoint[opts.region] ) {
        throw MARK + "invalid region '" + opts.region + "'";
    }

    return self;
};

// inherit from GreenQloud
util.inherits(S3, greenqloud.GreenQloud);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js/amazon.js

S3.prototype.host = function() {
    return endPoint[this.region()];
};

S3.prototype.version = function() {
    return version;
};

S3.prototype.locationConstraint = function() {
    return locationConstraint[this.region()];
};

// From: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html
//
// Just the date for this service.
S3.prototype.addCommonOptions = function(options, args) {
    var self = this;

    // always add a Date header
    options.headers.Date = dateFormat(new Date(), "UTC:ddd, dd mmm yyyy HH:MM:ss Z");

    // make the strToSign, create the signature and sign it
    var strToSign = self.strToSign(options, args);
    var signature = self.signature(strToSign);
    options.headers.Authorization = 'AWS ' + self.accessKeyId() + ':' + signature;
};

// From: http://docs.amazonwebservices.com/AmazonS3/latest/dev/RESTAuthentication.html
//
// Returns a strToSign for this request.
S3.prototype.strToSign = function(options, args) {
    var self = this;

    // start creating the string we need to sign
    var strToSign = '';
    strToSign += options.method + "\n";

    // add the following headers (if available)
    _.each(['Content-MD5', 'Content-Type', 'Date'], function(hdrName) {
        if ( _.isString( options.headers[hdrName] ) ) {
            strToSign += options.headers[hdrName];
        }
        strToSign += "\n";
    });

    // grep out all of the x-amz-* headers
    var amzHeaders = _(options.headers)
        .chain()
        .keys()
        // .map( function(hdr) { return h.toLowerCase(); } )
        .select( function(hdr) {
            return hdr.toLowerCase().match(/^x-amz-/) ? true : false;
        })
        .sortBy( function(hdr) { return hdr; } )
        .value();

    // add the x-amz-* headers to the strToSign in the correct order
    _.each(amzHeaders, function(hdr) {
        strToSign += hdr.toLowerCase() + ':';

        // concat all the headers and their values together (removing leading and trailing whitespace)
        var headerValue;
        if ( _.isArray(options.headers[hdr]) ) {
            headerValue = _(options.headers[hdr])
                .chain()
                .map(function(val) { return val.replace(/^\s+|\s+$/g, ''); })
                .value()
                .join(',');
        }
        else {
            headerValue = options.headers[hdr].replace(/^\s+|\s+$/g, '');
        }

        // condense all whitespace into a single space
        headerValue.replace(/\s+/g, ' ');

        strToSign += headerValue + "\n";
    });

    // add the CanonicalizedResource (bucket, path (defined by ObjectName) and sub-resource (defined by params))
    if ( _.isUndefined(args.BucketName) ) {
        strToSign += '/';
    }
    else {
        strToSign += '/' + args.BucketName + '/';
    }
    if ( ! _.isUndefined(args.ObjectName) ) {
        strToSign += esc(args.ObjectName);
    }

    // add the sub-resources (such as versioning, location, acl, torrent, versionid) but not things like max-keys,
    // prefix or other query parameters
    if ( options.params.length ) {
        strToSign += _(options.params)
            .chain()
            .filter(function(pair) { return validSubresource[pair.name]; } )
            .sortBy(function(pair) { return pair.name; } )
            .map(function(pair){
                return _.isUndefined(pair.value) ? pair.name : pair.name + '=' + pair.value;
            })
            .reduce(function(memo, pairStr) {
                return memo === '' ? '?' + pairStr : memo + '&' + pairStr;
            }, '')
            .value()
        ;
    }

    // console.log('StrToSign :', strToSign + '(Ends)');

    return strToSign;
};

// From: http://docs.amazonwebservices.com/AmazonS3/latest/dev/RESTAuthentication.html
//
// Returns a signature for this request.
S3.prototype.signature = function(strToSign) {
    var self = this;

    // sign the request string
    var signature = crypto
        .createHmac('sha1', this.secretAccessKey())
        .update(strToSign)
        .digest('base64');

    // console.log('Signature :', signature);

    return signature;
};

// Whenever anything goes wrong with S3, it'll give back XML, even for those operations which usually respond with
// "204 - No Content"
S3.prototype.extractBodyWhenError = function(options) {
    return 'xml';
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

_.each(operations, function(operation, operationName) {
    S3.prototype[operationName] = awssum.makeOperation(operation);
});

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.S3 = S3;

// --------------------------------------------------------------------------------------------------------------------
