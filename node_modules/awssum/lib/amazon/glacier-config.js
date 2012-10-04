// --------------------------------------------------------------------------------------------------------------------
//
// glacier-config.js - config for AWS Glacier
//
// Copyright (c) 2011, 2012 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

function pathVaults(options, args) {
    return '/' + this.awsAccountId() + '/vaults';
}

function pathVault(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName;
}

function pathVaultNotificationConfiguration(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/notification-configuration';
}

function pathVaultArchives(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/archives';
}

function pathVaultArchive(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/archives/' + args.ArchiveId;
}

function pathVaultMultipartUploads(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/multipart-uploads';
}

function pathVaultMultipartUpload(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/multipart-uploads/' + args.UploadId;
}

function pathVaultJobs(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/jobs';
}

function pathVaultJob(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/jobs/' + args.JobId;
}

function pathVaultJobOutput(options, args) {
    return '/' + this.awsAccountId() + '/vaults/' + args.VaultName + '/jobs/' + args.JobId + '/output';
}

function bodyVaultNotificationConfiguration(options, args) {
    return JSON.stringify({
        SNSTopic : args.SNSTopic,
        Events   : args.Events,
    });
}

function bodyBatchGetItems(options, args) {
    var data = {
        RequestItems : args.RequestItems,
    };

    // console.log(JSON.stringify(data));

    return JSON.stringify(data);
}

function bodyInitiateJob(options, args) {
    var data = {
        Type : args.Type,
    };

    var names = [ 'ArchiveId', 'Description', 'SNSTopic', 'Format' ];
    names.forEach(function(v, i) {
        if ( args[v] ) {
            data[v] = args[v];
        }
    });

    return JSON.stringify(data);
}

// --------------------------------------------------------------------------------------------------------------------

var required        = { required : true,  type : 'param'       };
var optional        = { required : false, type : 'param'       };
var requiredArray   = { required : true,  type : 'param-array' };
var optionalArray   = { required : false, type : 'param-array' };
var requiredData    = { required : true,  type : 'param-data'  };
var optionalData    = { required : false, type : 'param-data'  };
var requiredSpecial = { required : true,  type : 'special'     };
var optionalSpecial = { required : false, type : 'special'     };

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // Vault Operations

    CreateVault : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-put.html',
        method : 'PUT',
        path : pathVault,
        args : {
            VaultName : requiredSpecial,
            Limit  : optional,
            Marker : optional,
        },
    },

    DeleteVault : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-delete.html',
        // request
        method : 'DELETE',
        path : pathVault,
        args : {
            VaultName : requiredSpecial,
        },
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    DescribeVault : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-get.html',
        // request
        method : 'GET',
        path : pathVault,
        args : {
            VaultName : requiredSpecial,
        },
    },

    ListVaults : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vaults-get.html',
        method : 'GET',
        path : pathVaults,
        args : {
            Limit  : {
                'name'     : 'limit',
                'type'     : 'param',
                'required' : false,
            },
            Marker : {
                'name'     : 'marker',
                'type'     : 'param',
                'required' : false,
            },
        },
    },

    SetVaultNotificationConfiguration : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-put.html',
        method : 'PUT',
        path : pathVaultNotificationConfiguration,
        args : {
            VaultName : requiredSpecial,
            SNSTopic  : requiredSpecial,
            Events    : requiredSpecial,
        },
        body : bodyVaultNotificationConfiguration,
    },

    GetVaultNotifications : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-get.html',
        method : 'GET',
        path : pathVaultNotificationConfiguration,
        args : {
            VaultName : requiredSpecial,
        },
    },

    DeleteVaultNotifications : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-notifications-delete.html',
        // request
        method : 'DELETE',
        path : pathVaultNotificationConfiguration,
        args : {
            VaultName : requiredSpecial,
        },
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    // Archive Operations

    UploadArchive : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-archive-post.html',
        method : 'POST',
        path : pathVaultArchives,
        args : {
            VaultName : requiredSpecial,
            ContentLength : {
                name     : 'Content-Length',
                required : true,
                type     : 'header',
            },
            ArchiveDescription : {
                name     : 'x-amz-archive-description',
                required : false,
                type     : 'header',
            },
            ContentSha256 : {
                name     : 'x-amz-content-sha256',
                required : true,
                type     : 'header',
            },
            Sha256TreeHash : {
                name     : 'x-amz-sha256-tree-hash',
                required : true,
                type     : 'header',
            },
            Body : {
                required : true,
                type     : 'body',
            },
        },
        // response
        statusCode: 201,
        extractBody : 'none',
    },

    DeleteArchive : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-archive-delete.html',
        method : 'DELETE',
        path : pathVaultArchive,
        args : {
            VaultName : requiredSpecial,
            ArchiveId : requiredSpecial,
        },
        // response
        statusCode : 204,
        extractBody : 'none',
    },

    // Multipart Upload Operations

    InitiateMultipartUpload : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html',
        // request
        method : 'POST',
        path : pathVaultMultipartUploads,
        args : {
            VaultName : requiredSpecial,
            PartSize : {
                'name'     : 'x-amz-part-size',
                'type'     : 'header',
                'required' : true,
            },
            ArchiveDescription : {
                'name'     : 'x-amz-archive-description',
                'type'     : 'header',
                'required' : true,
            },
        },
        // response
        statusCode : 201,
        extractBody : 'none',
    },

    UploadPart : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-upload-part.html',
        method : 'PUT',
        path : pathVaultMultipartUpload,
        args : {
            VaultName : requiredSpecial,
            UploadId : requiredSpecial,
            ContentLength : {
                name     : 'Content-Length',
                required : false,
                type     : 'header',
            },
            ContentRange : {
                name     : 'Content-Range',
                required : true,
                type     : 'header',
            },
            ContentSha256 : {
                name     : 'x-amz-content-sha256',
                required : true,
                type     : 'header',
            },
            Sha256TreeHash : {
                name     : 'x-amz-sha256-tree-hash',
                required : true,
                type     : 'header',
            },
            Body : {
                required : true,
                type     : 'body',
            },
        },
    },

    CompleteMultipartUpload : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-complete-upload.html',
        // request
        method : 'POST',
        path : pathVaultMultipartUpload,
        args : {
            VaultName : requiredSpecial,
            UploadId : requiredSpecial,
            Sha256TreeHash : {
                name     : 'x-amz-sha256-tree-hash',
                required : true,
                type     : 'header',
            },
            ArchiveSize : {
                'name'     : 'x-amz-archive-size',
                'type'     : 'header',
                'required' : true,
            },
        },
        // response
        statusCode : 201,
        extractBody : 'none',
    },

    AbortMultipartUpload : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-abort-upload.html',
        // request
        method : 'DELETE',
        path : pathVaultMultipartUpload,
        args : {
            VaultName : requiredSpecial,
            UploadId : requiredSpecial,
        },
        // response
        statusCode : 204,
        extractBody : 'none',
    },

    ListParts : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-list-parts.html',
        method : 'GET',
        path : pathVaultMultipartUpload,
        args : {
            VaultName : requiredSpecial,
            UploadId : requiredSpecial,
            Limit  : {
                'name'     : 'limit',
                'type'     : 'param',
                'required' : false,
            },
            Marker : {
                'name'     : 'marker',
                'type'     : 'param',
                'required' : false,
            },
        },
    },

    ListMultipartUploads : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-multipart-list-uploads.html',
        method : 'GET',
        path : pathVaultMultipartUploads,
        args : {
            VaultName : requiredSpecial,
            Limit  : {
                'name'     : 'limit',
                'type'     : 'param',
                'required' : false,
            },
            Marker : {
                'name'     : 'marker',
                'type'     : 'param',
                'required' : false,
            },
        },
    },

    // Job Operations

    InitiateJob : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-initiate-job-post.html',
        // request
        method : 'POST',
        path : pathVaultJobs,
        args : {
            VaultName   : requiredSpecial,
            Type        : requiredSpecial,
            ArchiveId   : optionalSpecial,
            Description : optionalSpecial,
            Format      : optionalSpecial,
            SNSTopic    : optionalSpecial,
        },
        body : bodyInitiateJob,
        // response
        statusCode : 202,
        extractBody : 'none',
    },

    DescribeJob : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-describe-job-get.html',
        // request
        method : 'GET',
        path : pathVaultJob,
        args : {
            VaultName : requiredSpecial,
            JobId     : requiredSpecial,
        },
    },

    GetJobOutput : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-job-output-get.html',
        // request
        method : 'GET',
        path : pathVaultJobOutput,
        args : {
            VaultName : requiredSpecial,
            JobId     : requiredSpecial,
            Range : {
                name     : 'Range',
                required : false,
                type     : 'header',
            },
        },
        // response
        extractBody : 'blob',
        extractBodyWhenError : 'json',
    },

    ListJobs : {
        url : 'http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-jobs-get.html',
        // request
        method : 'GET',
        path : pathVaultJobs,
        args : {
            VaultName : requiredSpecial,
            Completed : {
                name     : 'completed',
                required : false,
                type     : 'param',
            },
            Limit : {
                name     : 'limit',
                required : false,
                type     : 'param',
            },
            Marker : {
                name     : 'marker',
                required : false,
                type     : 'param',
            },
            StatusCode : {
                name     : 'statuscode',
                required : false,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
