// --------------------------------------------------------------------------------------------------------------------
//
// rackspacecloud/authentication.js - class for RackspaceCloud Authentication Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
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
var base = require('./base');

// --------------------------------------------------------------------------------------------------------------------
// package variables

var MARK = 'RSC-authentication: ';

var version = 'v1.1';

// From: http://docs.rackspace.com/cdns/api/v1.0/cdns-devguide/content/Authentication-d1e647.html
var endPoint = {};
endPoint[base.UK] = 'lon.auth.api.rackspacecloud.com';
endPoint[base.US] = 'auth.api.rackspacecloud.com';

// --------------------------------------------------------------------------------------------------------------------
// constructor

var Authentication = function(username, apiKey, region) {
    var self = this;

    // call the superclass for initialisation
    Authentication.super_.call(this, username, apiKey, region);

    // check the region is valid
    if ( ! endPoint[region] ) {
        throw MARK + "invalid region '" + region + "'";
    }

    return self;
};

// inherit from Amazon
util.inherits(Authentication, base.Base);

// --------------------------------------------------------------------------------------------------------------------
// methods we need to implement from awssum.js, rackspacecloud/base.js

Authentication.prototype.host = function() {
    return endPoint[this.region()];
};

Authentication.prototype.decodeResponse = function(res) {
    var data = JSON.parse(res.body);

    // let's also get out the Account ID since RackspaceCloud doesn't give it to us directly
    // e.g. https://servers.api.rackspacecloud.com/v1.0/123456
    var regex = /\/(\d+)$/g;
    var match = regex.exec( data.auth.serviceCatalog.cloudServers[0].publicURL );
    var accountId = match[1];
    data.accountId = accountId;

    return data;
};

// --------------------------------------------------------------------------------------------------------------------
// operations on the service

Authentication.prototype.getAuthToken = function(args, callback) {
    var self = this;
    if ( callback === undefined ) {
        callback = args;
        args = {};
    }
    args = args || {};

    // create the request
    this.performRequest({
        method : 'POST',
        path : '/' + version + '/auth',
        body : JSON.stringify({ credentials : { username : self.username(), key : self.apiKey() } }),
        statsuCode : 200, // and 203!
    }, callback);
};

// --------------------------------------------------------------------------------------------------------------------
// exports

exports.Authentication = Authentication;

// --------------------------------------------------------------------------------------------------------------------
