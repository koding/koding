// --------------------------------------------------------------------------------------------------------------------
//
// contacts-config.js - Contacts API for Yahoo!
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

// requires
// none

function pathContacts(options, args) {
    return '/' + this.version() + '/user/' + this.yahooGuid() + '/contacts';
}

function pathGetContact(options, args) {
    return '/' + this.version() + '/user/' + this.yahooGuid() + '/contact/' + args.Cid;
}

// --------------------------------------------------------------------------------------------------------------------

// From: http://developer.yahoo.com/social/rest_api_guide/contact_api.html
//
// * http://developer.yahoo.com/social/rest_api_guide/contacts-resource.html
// * http://developer.yahoo.com/social/rest_api_guide/contact-resource.html
// ...

// GET : 200
// POST : 200, 201
// PUT : 200, 202 or 204
// DELETE : 200, 202
// HEAD : ???
// OPTIONS : ???

module.exports = {

    GetContacts : {
        // request
        path : pathContacts,
        args : {
            View : {
                type     : 'param',
                required : false,
                name     : 'view',
            },
            Start : {
                type     : 'param',
                required : false,
                name     : 'start',
            },
            Count : {
                type     : 'param',
                required : false,
                name     : 'count',
            },
            SortFields : {
                type     : 'param',
                required : false,
                name     : 'sort-fields',
            },
            Sort : {
                type     : 'param',
                required : false,
                name     : 'sort',
            },
        },
        // response
        // extractBodyWhenError : 'xml',
    },

    GetContact : {
        // request
        path : pathGetContact,
        args : {
            Cid : {
                type     : 'special',
                required : true,
            },
        },
        // response
        // extractBodyWhenError : 'xml',
    },

    DeleteContact : {
        // request
        method : 'DELETE',
        path : pathGetContact,
        args : {
            Cid : {
                type     : 'special',
                required : true,
            },
        },
        // response
        extractBodyWhenError : 'string',
    },

};

// --------------------------------------------------------------------------------------------------------------------
