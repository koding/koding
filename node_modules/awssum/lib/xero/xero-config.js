// --------------------------------------------------------------------------------------------------------------------
//
// xero-config.js - config for Xero
//
// Copyright (c) 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------
// requires

var data2xml = require('data2xml');

function pathAttachments(options, args) {
    return '/api.xro/2.0/' + args.EndPoint + '/' + args.Guid + '/Attachments/';
}

function pathAttachment(options, args) {
    return '/api.xro/2.0/' + args.EndPoint + '/' + args.Guid + '/Attachments/' + args.Filename;
}

// --------------------------------------------------------------------------------------------------------------------
// body functions

function bodyAttachments(options, args) {
    if ( !Array.isArray(args.Attachments) ) {
        args.Attachments = [ args.Attachments ];
    }

    // create the data
    var data = {
        Contact : args.Attachments,
    };

    return data2xml('Attachments', data);
}

function bodyContacts(options, args) {
    if ( !Array.isArray(args.Contacts) ) {
        args.Contacts = [ args.Contacts ];
    }

    // create the data
    var data = {
        Contact : args.Contacts,
    };

    return data2xml('Contacts', data);
}

// --------------------------------------------------------------------------------------------------------------------

// From: http://blog.xero.com/developer/api/
//
// * http://blog.xero.com/developer/api/Accounts
// * http://blog.xero.com/developer/api/Attachments
// * http://blog.xero.com/developer/api/BankTransactions
// * http://blog.xero.com/developer/api/Branding-Themes
// * http://blog.xero.com/developer/api/Contacts
// * http://blog.xero.com/developer/api/Credit%20Notes
// * http://blog.xero.com/developer/api/Currencies
// * http://blog.xero.com/developer/api/Employees
// * http://blog.xero.com/developer/api/Expense-Claims
// * http://blog.xero.com/developer/api/Invoices
// * http://blog.xero.com/developer/api/Items
// * http://blog.xero.com/developer/api/Journals
// * http://blog.xero.com/developer/api/Manual-Journals
// * http://blog.xero.com/developer/api/Organisation
// * http://blog.xero.com/developer/api/Payments
// * http://blog.xero.com/developer/api/Receipts
// * http://blog.xero.com/developer/api/Reports
// * http://blog.xero.com/developer/api/Tax%20Rates
// * http://blog.xero.com/developer/api/Tracking%20Categories
// * http://blog.xero.com/developer/api/Users

module.exports = {

    // ---
    // Attachments - http://blog.xero.com/developer/api/attachments/

    ListAttachments : {
        // request
        path : pathAttachments,
        args : {
            EndPoint : {
                required : true,
                type     : 'special',
            },
            Guid : {
                required : true,
                type     : 'special',
            },
            Where : {
                required : false,
                type     : 'param',
                name     : 'where',
            },
            Order : {
                required : false,
                type     : 'param',
                name     : 'order',
            },
        },
        // response
    },

    GetAttachment : {
        // request
        path : pathAttachment,
        args : {
            EndPoint : {
                required : true,
                type     : 'special',
            },
            Guid : {
                required : true,
                type     : 'special',
            },
            Filename : {
                required : true,
                type     : 'special',
            },
        },
        // response
    },

    CreateAttachment : {
        // request
        method : 'POST',
        path : pathAttachment,
        args : {
            EndPoint : {
                required : true,
                type     : 'special',
            },
            Guid : {
                required : true,
                type     : 'special',
            },
            Filename : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyAttachments,
        // response
    },

    UpdateAttachment : {
        // request
        method : 'PUT',
        path : pathAttachment,
        args : {
            Attachments : {
                type     : 'special',
                required : true,
            },
        },
        body : bodyAttachments,
        // response
    },

    // ---
    // Accounts - http://blog.xero.com/developer/api/accounts/

    ListAccounts : {
        // request
        path : '/api.xro/2.0/Accounts',
        args : {
            ContactID : {
                required : false,
                type     : 'special',
            },
            ModifiedAfter : {
                required : false,
                type     : 'header',
                name     : 'If-Modified-Since',
            },
            Where : {
                required : false,
                type     : 'param',
                name     : 'where',
            },
            Order : {
                required : false,
                type     : 'param',
                name     : 'order',
            },
        },
        // response
    },

    // ---
    // Contacts - http://blog.xero.com/developer/api/contacts/

    ListContacts : {
        // request
        path : '/api.xro/2.0/Contacts',
        args : {
            ContactID : {
                required : false,
                type     : 'special',
            },
            ModifiedAfter : {
                required : false,
                type     : 'header',
                name     : 'If-Modified-Since',
            },
            Where : {
                required : false,
                type     : 'param',
                name     : 'where',
            },
            Order : {
                required : false,
                type     : 'param',
                name     : 'order',
            },
        },
        // response
    },

    CreateContacts : {
        // request
        method : 'PUT', // inconsistent with other Create commands
        path : '/api.xro/2.0/Contacts',
        args : {
            Contacts : {
                type     : 'special',
                required : true,
            },
        },
        body : bodyContacts,
        // response
    },

    UpdateContacts : {
        // request
        method : 'POST', // inconsistent with other Update commands
        path : '/api.xro/2.0/Contacts',
        args : {
            Contacts : {
                type     : 'special',
                required : true,
            },
        },
        body : bodyContacts,
        // response
    },

    // ---
    // Employees - http://blog.xero.com/developer/api/employees/

    ListEmployees : {
        // request
        path : '/api.xro/2.0/Employees',
        args : {},
        // response
    },

    // ---
    // Items - http://blog.xero.com/developer/api/Items

    ListItems : {
        // request
        path : '/api.xro/2.0/Items',
        args : {},
        // response
    },

    // ---
    // Organisation - http://blog.xero.com/developer/api/Organisation

    ListOrganisation : {
        // request
        path : '/api.xro/2.0/Organisation',
        args : {},
        // auth : true,
        // response
        extractBodyWhenError : 'application/x-www-form-urlencoded', // happens when we get a 401 - Unauthorised
    },

    // ---
    // Users - http://blog.xero.com/developer/api/users

    ListUsers : {
        // request
        path : '/api.xro/2.0/Users',
        args : {
            UserID : {
                required : false,
                type     : 'special',
            },
            ModifiedAfter : {
                required : false,
                type     : 'header',
                name     : 'If-Modified-Since',
            },
            Where : {
                required : false,
                type     : 'param',
                name     : 'where',
            },
            Order : {
                required : false,
                type     : 'param',
                name     : 'order',
            },
        },
        // auth : true,
        // response
        extractBodyWhenError : 'application/x-www-form-urlencoded', // happens when we get a 401 - Unauthorised
    },

};

// --------------------------------------------------------------------------------------------------------------------
