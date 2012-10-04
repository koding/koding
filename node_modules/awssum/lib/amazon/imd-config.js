// --------------------------------------------------------------------------------------------------------------------
//
// imd-config.js - config for AWS Instance Metadata
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

function path(options, args) {
    return '/' + args.Version + args.Category;
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    'ListApiVersions' : {
        'url' : 'http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html',
        // request
        'path' : '/',
        // response
        'extractBody' : 'string',
    },

    'Get' : {
        'url' : 'http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html',
        // request
        'path' : path,
        'args' : {
            Category : {
                'required' : true,
                'type'     : 'special',
            },
            Version : {
                'required' : true,
                'type'     : 'special',
            },
        },
        // response
        'extractBody' : 'string',
    },

};

// --------------------------------------------------------------------------------------------------------------------
