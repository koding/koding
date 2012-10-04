// --------------------------------------------------------------------------------------------------------------------
//
// importexport-config.js - config for AWS Import/Export
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var required = { required : true,  type : 'param'       };
var optional = { required : false, type : 'param'       };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    CancelJob : {
        url : 'http://docs.amazonwebservices.com/AWSImportExport/latest/DG/WebCancelJob.html',
        defaults : {
            Action : 'CancelJob',
        },
        args : {
            Action : required,
            JobId  : required,
        },
    },

    CreateJob : {
        url : 'http://docs.amazonwebservices.com/AWSImportExport/latest/DG/WebCreateJob.html',
        defaults : {
            Action : 'CreateJob',
        },
        args : {
            Action       : required,
            JobType      : required,
            Manifest     : required,
            ValidateOnly : optional,
        },
    },

    GetStatus : {
        url : 'http://docs.amazonwebservices.com/AWSImportExport/latest/DG/WebGetStatus.html',
        defaults : {
            Action : 'GetStatus',
        },
        args : {
            Action : required,
            JobId  : required,
        },
    },

    ListJobs : {
        url : 'http://docs.amazonwebservices.com/AWSImportExport/latest/DG/WebListJobs.html',
        defaults : {
            Action : 'ListJobs',
        },
        args : {
            Action  : required,
            Marker  : optional,
            MaxJobs : optional,
        },
    },

    UpdateJob : {
        url : 'http://docs.amazonwebservices.com/AWSImportExport/latest/DG/WebUpdateJob.html',
        defaults : {
            Action : 'UpdateJob',
        },
        args : {
            Action   : required,
            JobId    : required,
            JobType  : required,
            Manifest : required,
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
