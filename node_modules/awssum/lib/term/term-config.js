// --------------------------------------------------------------------------------------------------------------------
//
// term-config.js - config for Term
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// requires
// none

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // the only private resource for term.ie
    Echo : {
        // request
        path : '/oauth/example/echo_api.php',
        args : {
            Foo : {
                type     : 'param',
                required : false,
            },
            Bar : {
                type     : 'param',
                required : false,
            },
            Baz : {
                type     : 'param',
                required : false,
            },
        },
        // response
        extractBody : 'blob',
    },

};

// --------------------------------------------------------------------------------------------------------------------
