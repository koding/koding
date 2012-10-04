// --------------------------------------------------------------------------------------------------------------------
//
// s3-config.js - class for AWS Simple Storage Service
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var _ = require('underscore');
var data2xml = require('data2xml');
var crypto = require('crypto');

// --------------------------------------------------------------------------------------------------------------------

function hostBucket(options, args) {
    var self = this;
    return args.BucketName + '.' + self.host();
}

function pathObject(options, args) {
    var self = this;
    return '/' + args.ObjectName;
}

// http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
function headersMetaDataHeaders(options, args) {
    // let's check the MetaData arg
    if ( ! args.MetaData ) {
        return;
    }

    // add all of these as headers
    for(var key in args.MetaData) {
        options.headers['x-amz-meta-' + key] = args.MetaData[key];
    }
}

function bodyLocationConstraint(options, args) {
    var self = this;

    if ( !self.locationConstraint() ) {
        return '';
    }

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
        LocationConstraint : self.locationConstraint(),
    };

    return data2xml('CreateBucketConfiguration', data);
}

function bodyAccessControlPolicy(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
    };

    if ( args.OwnerId || args.DisplayName ) {
        data.Owner = {};
        if ( args.OwnerId ) {
            data.Owner.ID = args.OwnerId;
        }
        if ( args.DisplayName ) {
            data.Owner.DisplayName = args.DisplayName;
        }
    }

    if ( args.GranteeId || args.GranteeDisplayName || args.Permission ) {
        data.AccessControlList = {};
        if ( args.GranteeId || args.GranteeDisplayName ) {
            data.AccessControlList.Grant = {};
            data.AccessControlList.Grant.Grantee = {
                _attr : {
                    'xmlns:xsi' : 'http://www.w3.org/2001/XMLSchema-instance',
                    'xsi:type'  : 'CanonicalUser',
                },
            };
            if ( args.GranteeId ) {
                data.AccessControlList.Grant.Grantee.ID = args.GranteeId;
            }
            if ( args.GranteeDisplayName ) {
                data.AccessControlList.Grant.Grantee.DisplayName = args.GranteeDisplayName;
            }
            if ( args.Permission ) {
                data.AccessControlList.Grant.Permission = args.Permission;
            }
        }
    }

    return data2xml('AccessControlPolicy', data);
}

function bodyLifecycleConfiguration(options, args) {
    var self = this;

    // create the data
    var data = {
        'Rule' : [],
    };

    // loop through all the rules
    var rule;
    if ( args.Rules ) {
        args.Rules.forEach(function(v, i) {
            // create the new rule
            rule = {
                'Prefix' : v.Prefix,
                'Status' : v.Status,
                'Expiration' : {
                    'Days' : v.Days
                }
            };

            if ( v.ID ) {
                rule.ID = v.ID;
            }

            data.Rule.push(rule);
        });
    }

    return data2xml('LifecycleConfiguration', data);
}

function bodyPolicy(options, args) {
    var self = this;
    return JSON.stringify(args.BucketPolicy);
}

function bodyBucketLoggingStatus(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
    };

    // required
    if ( args.TargetBucket ) {
        data.LoggingEnabled = data.LoggingEnabled || {};
        data.LoggingEnabled.TargetBucket = args.TargetBucket;
    }

    // optional
    if ( args.TargetPrefix ) {
        data.LoggingEnabled = data.LoggingEnabled || {};
        data.LoggingEnabled.TargetPrefix = args.TargetPrefix;
    }

    // set the initial hierarchy
    data.LoggingEnabled = {
        Grant : {
            Grantee : {
                _attr : {
                    'xmlns:xsi' : 'http://www.w3.org/2001/XMLSchema-instance'
                },
            },
        },
    };

    // optional
    if ( args.GranteeId ) {
        data.LoggingEnabled.TargetGrants.Grant.Grantee._attr['xsi:type'] = "CanonicalUser";
        data.LoggingEnabled.TargetGrants.Grant.Grantee.ID = args.GranteeId;
    }
    else if ( args.EmailAddress ) {
        data.LoggingEnabled.TargetGrants.Grant.Grantee._attr['xsi:type'] = "AmazonCustomerByEmail";
        data.LoggingEnabled.TargetGrants.Grant.Grantee.EmailAddress = args.EmailAddress;
    }
    else if ( args.Uri ) {
        data.LoggingEnabled.TargetGrants.Grant.Grantee._attr['xsi:type'] = "Group";
        data.LoggingEnabled.TargetGrants.Grant.Grantee.URI = args.Uri;
    }

    if ( args.Permission ) {
        data.LoggingEnabled.TargetGrants.Grant.Permission = args.Permission;
    }

    return data2xml('BucketLoggingStatus', data);
}

function bodyNotificationConfiguration(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
    };

    if ( args.Topic ) {
        data.TopicConfiguration = data.TopicConfiguration || {};
        data.TopicConfiguration.Topic = args.Topic;
    }

    if ( args.Event ) {
        data.TopicConfiguration = data.TopicConfiguration || {};
        data.TopicConfiguration.Event = args.Event;
    }

    return data2xml('NotificationConfiguration', data);
}

function bodyRequestPaymentConfiguration(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
        Payer : args.Payer,
    };

    return data2xml('RequestPaymentConfiguration', data);
}

function bodyVersioningConfiguration(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
    };

    if ( args.Status ) {
        data.Status = args.Status;
    }

    if ( args.MfaDelete ) {
        data.MfaDelete = args.MfaDelete;
    }

    return data2xml('VersioningConfiguration', data);
}

function bodyWebsiteConfiguration(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
        IndexDocument : {
            Suffix : args.IndexDocument,
        }
    };

    if ( args.ErrorDocument ) {
        data.ErrorDocument = {};
        data.ErrorDocument.Key = args.ErrorDocument;
    }

    return data2xml('WebsiteConfiguration', data);
}

function bodyDelete(options, args) {
    var self = this;

    // create the data
    var data = {
        Object : [],
    };

    if ( args.Quiet ) {
        data.Quiet = 'true';
    }

    // loop through all the Objects
    args.Objects.forEach(function(v) {
        var o = {};
        if ( _.isObject(v) ) {
            o.Key       = v.Key;
            if ( v.VersionId ) {
                o.VersionId = v.VersionId;
            }
        }
        else {
            o.Key = v;
        }
        data.Object.push(o);
    });

    return data2xml('Delete', data);
}

function bodyCompleteMultipartUpload(options, args) {
    var self = this;

    // create the data
    var data = {
        Part : [],
    };

    // loop through all the Parts
    args.Parts.forEach(function(v) {
        // add each PartNumber and ETag
        var p = {
            PartNumber : v.PartNumber,
            ETag       : v.ETag,
        };
        data.Part.push(p);
    });

    return data2xml('CompleteMultipartUpload', data);
}

function extrasContentLength(options, args) {
    var self = this;

    // add the Content-Length header we need
    options.headers['Content-Length'] = args.ContentLength || Buffer.byteLength( options.body );
}

function extrasContentMd5(options, args) {
    var self = this;

    if(typeof options.body === "string" && !args.ContentMD5) {
        // get the MD5 of the body
        var md5 = crypto
            .createHash('md5')
            .update(options.body)
            .digest('base64');

        // add the Content-MD5 header we need
        options.headers['Content-MD5'] = md5;
    }
    else if (args.ContentMD5) {
        options.headers['Content-MD5'] = args.ContentMD5;
    }
}

function extrasCopySource(options, args) {
    var self = this;

    // add the x-amz-copy-source header we need
    options.headers['x-amz-copy-source'] = '/' + args.SourceBucket + '/' + args.SourceObject;
    if ( args.SourceVersionId ) {
        options.headers['x-amz-copy-source'] += '?versionId=' + args.SourceVersionId;
    }

    // HACK FOR AWS: When doing a request to CopyObject, AWS fails when sending a header of 'Content-Encoding=chunked'
    // which is Nodes default way of doing requests. ("A header you provided implies functionality that is not
    // implemented (Transfer-Encoding).") To work around this, we set a Content-Length of 0 so that the
    // 'Content-Encoding' header is not sent.
    //
    // Note: Found this after I figured out a solution : https://forums.aws.amazon.com/thread.jspa?threadID=50772
    options.headers['Content-Length'] = 0;
}

// --------------------------------------------------------------------------------------------------------------------

// From: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceOps.html
//
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
//
// From: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketOps.html
//
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
//
// From: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectOps.html
//
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPOST.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
// * http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html

module.exports = {

    // Operations on the Service

    ListBuckets : {
        // nothing!
    },

    // Operations on Buckets

    DeleteBucket : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    DeleteBucketLifecycle : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        defaults : {
            lifecycle : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            lifecycle : {
                required : true,
                type     : 'resource',
            },
        },
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    DeleteBucketPolicy : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        defaults : {
            policy : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            policy : {
                required : true,
                type     : 'resource',
            },
        },
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    DeleteBucketWebsite : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        defaults : {
            website : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            website : {
                required : true,
                type     : 'resource',
            },
        },
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    ListObjects : {
        // request
        host : hostBucket,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            Delimiter : {
                name     : 'delimiter',
                required : false,
                type     : 'param',
            },
            Marker : {
                name     : 'marker',
                required : false,
                type     : 'param',
            },
            MaxKeys : {
                name     : 'max-keys',
                required : false,
                type     : 'param',
            },
            Prefix : {
                name     : 'prefix',
                required : false,
                type     : 'param',
            },
        },
    },

    GetBucketAcl : {
        // request
        host : hostBucket,
        defaults : {
            acl : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            acl : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketLifecycle : {
        // request
        host : hostBucket,
        defaults : {
            lifecycle : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            lifecycle : {
                required : true,
                type     : 'resource',
            },
        },
        // response
        extractBody : 'none',
    },

    GetBucketPolicy : {
        // request
        host : hostBucket,
        defaults : {
            policy : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            policy : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketLocation : {
        // request
        host : hostBucket,
        defaults : {
            location : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            location : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketLogging : {
        // request
        host : hostBucket,
        defaults : {
            logging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            logging : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketNotification : {
        // request
        host : hostBucket,
        defaults : {
            notification : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            notification : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketObjectVersions : {
        // request
        host : hostBucket,
        defaults : {
            versions : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            versions : {
                required : true,
                type     : 'resource',
            },
            Delimiter : {
                name     : 'delimiter',
                required : false,
                type     : 'param',
            },
            KeyMarker : {
                name     : 'key-marker',
                required : false,
                type     : 'param',
            },
            MaxKeys : {
                name     : 'max-keys',
                required : false,
                type     : 'param',
            },
            Prefix : {
                name     : 'prefix',
                required : false,
                type     : 'param',
            },
            VersionIdMarker : {
                name     : 'version-id-marker',
                required : false,
                type     : 'param',
            },
        },
    },

    GetBucketRequestPayment : {
        // request
        host : hostBucket,
        defaults : {
            requestPayment : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            requestPayment : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketVersioning : {
        // request
        host : hostBucket,
        defaults : {
            versioning : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            versioning : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketWebsite : {
        // request
        host : hostBucket,
        defaults : {
            website : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            website : {
                required : true,
                type     : 'resource',
            },
        },
    },

    CheckBucket : {
        // request
        method : 'HEAD',
        host : hostBucket,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
        },
        // response
    },

    ListMultipartUploads : {
        // request
        host : hostBucket,
        defaults : {
            uploads : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            uploads : {
                required : true,
                type     : 'resource',
            },
        },
    },

    CreateBucket : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            LocationConstraint : function(args) { this.region(); }
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            Acl : {
                name     : 'x-amz-acl',
                required : false,
                type     : 'header',
            },
        },
        body : bodyLocationConstraint,
        // response
        extractBody : 'none',
    },

    PutBucketAcl : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            acl : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            acl : {
                required : true,
                type     : 'resource',
            },
            OwnerId : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyAccessControlPolicy,
        // response
        extractBody : 'none',
    },

    PutBucketLifecycle : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            lifecycle : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            lifecycle : {
                required : true,
                type     : 'resource',
            },
            Rules : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyLifecycleConfiguration,
        addExtras : extrasContentMd5,
        // response
        extractBody : 'none',
    },

    PutBucketPolicy : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            policy : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            policy : {
                required : true,
                type     : 'resource',
            },
            BucketPolicy : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyPolicy,
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    PutBucketLogging : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            logging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            logging : {
                required : true,
                type     : 'resource',
            },
            EmailAddress : {
                required : false,
                type     : 'special',
            },
            GranteeEmail : {
                required : false,
                type     : 'special',
            },
            Uri : {
                required : false,
                type     : 'special',
            },
            Permission : {
                required : false,
                type     : 'special',
            },
            TargetBucket : {
                required : false,
                type     : 'special',
            },
            TargetPrefix : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyBucketLoggingStatus,
        // response
        extractBody : 'none',
    },

    PutBucketNotification : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            logging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            logging : {
                required : true,
                type     : 'resource',
            },
            Topic : {
                required : false,
                type     : 'special',
            },
            Event : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyNotificationConfiguration,
        // request
        extractBody : 'none',
    },

    PutBucketRequestPayment : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            logging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            logging : {
                required : true,
                type     : 'resource',
            },
            Payer : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyRequestPaymentConfiguration,
        // response
        extractBody : 'none',
    },

    PutBucketVersioning : {
        method : 'PUT',
        host : hostBucket,
        defaults : {
            versioning : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            versioning : {
                required : true,
                type     : 'resource',
            },
            Status : {
                required : false,
                type     : 'special',
            },
            MfaDelete : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyVersioningConfiguration,
        // response
        extractBody : 'none',
    },

    PutBucketWebsite : {
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            website : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            website : {
                required : true,
                type     : 'resource',
            },
            IndexDocument : {
                required : true,
                type     : 'special',
            },
            ErrorDocument : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyWebsiteConfiguration,
        // response
        extractBody : 'none',
    },

    // Operations on Objects
    DeleteObject : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        path   : pathObject,
        args   : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
        },
        // response
        statusCode : 204,
        extractBody : 'none',
    },

    DeleteMultipleObjects : {
        // request
        method : 'POST',
        host   : hostBucket,
        defaults : {
            'delete' : undefined,
        },
        args : {
            'delete' : {
                required : true,
                type     : 'resource',
            },
            Objects : {
                required : true,
                type     : 'special',
            },
            Mfa : {
                name     : 'x-amz-mfa',
                required : false,
                type     : 'header',
            },
        },
        body : bodyDelete,
        addExtras : extrasContentMd5,
    },

    GetObject : {
        // request
        host : hostBucket,
        path : pathObject,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            ResponseContentType : {
                name     : 'response-content-type',
                required : false,
                type     : 'param',
            },
            ResponseContentLanguage : {
                name     : 'response-content-language',
                required : false,
                type     : 'param',
            },
            ResponseExpires : {
                name     : 'response-expires',
                required : false,
                type     : 'param',
            },
            ResponseCacheControl : {
                name     : 'response-cache-control',
                required : false,
                type     : 'param',
            },
            ResponseContentDisposition : {
                name     : 'response-content-disposition',
                required : false,
                type     : 'param',
            },
            ResponseContentEncoding : {
                name     : 'response-content-encoding',
                required : false,
                type     : 'param',
            },
            VersionId : {
                name     : 'versionId',
                required : false,
                type     : 'param',
            },
        },
        // response
        extractBody : 'blob',
    },

    GetObjectAcl : {
        // request
        host : hostBucket,
        path : pathObject,
        defaults : {
            acl : undefined,
        },
        args : {
            acl : {
                required : true,
                type     : 'resource',
            },
            VersionId : {
                name     : 'versionId',
                required : false,
                type     : 'param',
            },
        },
    },

    GetObjectTorrent : {
        // request
        host : hostBucket,
        path : pathObject,
        defaults : {
            torrent : undefined,
        },
        args : {
            torrent : {
                required : true,
                type     : 'resource',
            },
        },
        // response
        extractBody : 'blob',
    },

    GetObjectMetadata : {
        // request
        method : 'HEAD',
        host : hostBucket,
        path : pathObject,
        args : {
            Range : {
                required : false,
                type     : 'param',
            },
            IfModifiedSince : {
                name     : 'If-Modified-Since',
                required : false,
                type     : 'param',
            },
            IfUnmodifiedSince : {
                name     : 'If-Unmodified-Since',
                required : false,
                type     : 'param',
            },
            IfMatch : {
                name     : 'If-Match',
                required : false,
                type     : 'param',
            },
            IfNoneMatch : {
                name     : 'If-None-Since',
                required : false,
                type     : 'param',
            },
        },
        // response
        extractBody : 'none',
    },

    // PostObject, // Web Stuff

    PutObject : {
        // request
        method : 'PUT',
        host   : hostBucket,
        path   : pathObject,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            CacheControl : {
                name     : 'Cache-Control',
                required : false,
                type     : 'header',
            },
            ContentDisposition : {
                name     : 'Content-Disposition',
                required : false,
                type     : 'header',
            },
            ContentEncoding : {
                name     : 'Content-Encoding',
                required : false,
                type     : 'header',
            },
            // If your body is a string, run Buffer.byteLength(options.body) to calculate this
            ContentLength : {
                name     : 'Content-Length',
                required : true,
                type     : 'header',
            },
            // Set automatically unless the body is a ReadableStream.
            ContentMD5 : {
                name     : 'Content-MD5',
                required : false,
                type     : 'header-base64',
            },
            ContentType : {
                name     : 'Content-Type',
                required : false,
                type     : 'header',
            },
            Expect : {
                required : false,
                type     : 'header',
            },
            Expires : {
                required : false,
                type     : 'header',
            },
            Acl : {
                name     : 'x-amz-acl',
                required : false,
                type     : 'header',
            },
            MetaData : {
                required : false,
                type     : 'special',
            },
            ServerSideEncryption : {
                name     : 'x-amz-server-side-encryption',
                required : false,
                type     : 'header',
            },
            StorageClass : {
                name     : 'x-amz-storage-class',
                required : false,
                type     : 'header',
            },
            Body : {
                required : true,
                type     : 'body',
            },
        },
        addExtras : [ headersMetaDataHeaders, extrasContentMd5 ],
        // response
        extractBody : 'none',
    },

    PutObjectAcl : {
        // request
        host : hostBucket,
        path : pathObject,
        defaults : {
            acl : undefined,
        },
        args : {
            acl : {
                required : true,
                type     : 'resource',
            },
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            CacheControl : {
                name     : 'Cache-Control',
                required : false,
                type     : 'header',
            },
            ContentDisposition : {
                name     : 'Content-Disposition',
                required : false,
                type     : 'header',
            },
            ContentEncoding : {
                name     : 'Content-Encoding',
                required : false,
                type     : 'header',
            },
            // set by the request after generating the XML
            ContentMD5 : {
                name     : 'Content-MD5',
                required : false,
                type     : 'header-base64',
            },
            ContentType : {
                name     : 'Content-Type',
                required : false,
                type     : 'header',
            },
            Expect : {
                required : false,
                type     : 'header',
            },
            Expires : {
                required : false,
                type     : 'header',
            },
            Acl : {
                name     : 'x-amz-acl',
                required : false,
                type     : 'header',
            },
        },
        body : bodyAccessControlPolicy,
        // response
        extractBody : 'none',
    },

    CopyObject : {
        // request
        method : 'PUT',
        host   : hostBucket,
        path   : pathObject,
        args : {
            Acl : {
                name : 'x-amz-acl',
                required : false,
                type : 'header',
            },
            SourceBucket : {
                required : true,
                type : 'special',
            },
            SourceObject : {
                required : true,
                type : 'special',
            },
            MetadataDirective : {
                name : 'x-amz-metadata-directive',
                required : false,
                type : 'header',
            },
            CopySourceIfMatch : {
                name : 'x-amz-copy-source-if-match',
                required : false,
                type : 'header',
            },
            CopySourceIfNoneMatch : {
                name : 'x-amz-copy-source-if-none-match',
                required : false,
                type : 'header',
            },
            CopySourceIfUnmodifiedSince : {
                name : 'x-amz-copy-source-if-unmodified-since',
                required : false,
                type : 'header',
            },
            CopySourceIfModifiedSince : {
                name : 'x-amz-copy-source-if-modified-since',
                required : false,
                type : 'header',
            },
            ServerSideEncryption : {
                name : 'x-amz-server-side-encryption',
                required : false,
                type : 'header',
            },
            StorageClass : {
                name : 'x-amz-storage-class',
                required : false,
                type : 'header',
            },
        },
        addExtras : extrasCopySource,
    },

    InitiateMultipartUpload : {
        // request
        method   : 'POST',
        host     : hostBucket,
        path     : pathObject,
        defaults : {
            uploads : undefined,
        },
        args     : {
            uploads : {
                required : true,
                type     : 'resource',
            },
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            CacheControl : {
                name     : 'Cache-Control',
                required : false,
                type     : 'header',
            },
            ContentDisposition : {
                name     : 'Content-Disposition',
                required : false,
                type     : 'header',
            },
            ContentEncoding : {
                name     : 'Content-Encoding',
                required : false,
                type     : 'header',
            },
            ContentType : {
                name     : 'Content-Type',
                required : false,
                type     : 'header',
            },
            Expires : {
                required : false,
                type     : 'header',
            },
            Acl : {
                name     : 'x-amz-acl',
                required : false,
                type     : 'header',
            },
            MetaData : {
                required : false,
                type     : 'special',
            },
            ServerSideEncryption : {
                name     : 'x-amz-server-side-encryption',
                required : false,
                type     : 'header',
            },
            StorageClass : {
                name     : 'x-amz-storage-class',
                required : false,
                type     : 'header',
            },
        },
        addExtras : headersMetaDataHeaders,
    },

    UploadPart : {
        // request
        method : 'PUT',
        host   : hostBucket,
        path   : pathObject,
        args   : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            PartNumber : {
                name     : 'partNumber',
                required : true,
                type     : 'param',
            },
            UploadId : {
                name     : 'uploadId',
                required : true,
                type     : 'param',
            },
            // ContentLength set by NodeJS
            ContentMD5 : {
                name     : 'Content-MD5',
                required : false,
                type     : 'header-base64',
            },
            Expect : {
                required : false,
                type     : 'header',
            },
        },
        // response
        extractBody : 'none',
    },

    UploadPartCopy : {
        // request
        method : 'PUT',
        host   : hostBucket,
        path   : pathObject,
        args   : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            PartNumber : {
                name     : 'partNumber',
                required : true,
                type     : 'param',
            },
            UploadId : {
                name     : 'uploadId',
                required : true,
                type     : 'param',
            },
            SourceBucket : {
                required : true,
                type : 'special',
            },
            SourceObject : {
                required : true,
                type : 'special',
            },
            CopySourceIfMatch : {
                name : 'x-amz-copy-source-if-match',
                required : false,
                type : 'header',
            },
            CopySourceIfNoneMatch : {
                name : 'x-amz-copy-source-if-none-match',
                required : false,
                type : 'header',
            },
            CopySourceIfUnmodifiedSince : {
                name : 'x-amz-copy-source-if-unmodified-since',
                required : false,
                type : 'header',
            },
            CopySourceIfModifiedSince : {
                name : 'x-amz-copy-source-if-modified-since',
                required : false,
                type : 'header',
            },
        },
        addExtras : extrasCopySource,
    },

    CompleteMultipartUpload : {
        // request
        method : 'POST',
        host   : hostBucket,
        path   : pathObject,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            UploadId : {
                name     : 'uploadId',
                required : true,
                type     : 'param',
            },
            Parts : {
                required : true,
                type     : 'special',
            },
        },
        body : bodyCompleteMultipartUpload,
    },

    AbortMultipartUpload : {
        // request
        method : 'DELETE',
        host   : hostBucket,
        path   : pathObject,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            UploadId : {
                name     : 'uploadId',
                required : true,
                type     : 'param',
            },
        },
        // response
        extractBody : 'none',
    },

    ListParts : {
        // request
        host   : hostBucket,
        path   : pathObject,
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            ObjectName : {
                required : true,
                type     : 'special',
            },
            UploadId : {
                name     : 'uploadId',
                required : true,
                type     : 'param',
            },
        },
    },
};

// --------------------------------------------------------------------------------------------------------------------
