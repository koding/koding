// --------------------------------------------------------------------------------------------------------------------
//
// sts-config.js - config for AWS Security Token Service
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    GetFederationToken : {
        url : 'http://docs.amazonwebservices.com/STS/latest/APIReference/API_GetFederationToken.html',
        defaults : {
            Action : 'GetFederationToken',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DurationSeconds : {
                required : false,
                type     : 'param',
            },
            Name : {
                required : true,
                type     : 'param',
            },
            Policy : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetSessionToken : {
        url : 'http://docs.amazonwebservices.com/STS/latest/APIReference/API_GetSessionToken.html',
        defaults : {
            Action : 'GetSessionToken',
        },
        args : {
            Action : {
                required : true,
                type     : 'param',
            },
            DurationSeconds : {
                required : false,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
