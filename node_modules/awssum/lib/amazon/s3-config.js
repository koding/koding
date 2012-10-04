// --------------------------------------------------------------------------------------------------------------------
//
// s3-config.js - config for AWS Simple Storage Service
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
var esc = require('../esc');

// --------------------------------------------------------------------------------------------------------------------

function hostBucket(options, args) {
    var self = this;
    return args.BucketName + '.' + self.host();
}

function pathObject(options, args) {
    var self = this;
    return '/' + esc(args.ObjectName);
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

    if ( !args.AccessControlPolicy ) {
        return '';
    }

    return data2xml('AccessControlPolicy', args.AccessControlPolicy);
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

function bodyTagging(options, args) {
    var self = this;

    // create the data
    var data = {
        _attr : { 'xmlns' : 'http://s3.amazonaws.com/doc/2006-03-01/' },
        TagSet : {
            Tag : [],
        }
    };

    args.Tags.forEach(function(t, i) {
        data.TagSet.Tag.push({
            Key   : t.Key,
            Value : t.Value,
        });
    });

    // console.log(data);

    return data2xml('Tagging', data);
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
        // Amazon hashes on a buffer, so convert body to match
        var body = new Buffer(options.body);
        var md5 = crypto
            .createHash('md5')
            .update(body)
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

module.exports = {

    // Operations on the Service

    ListBuckets : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html',
        // nothing!
    },

    // Operations on Buckets

    DeleteBucket : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html',
        // request
        method : 'DELETE',
        host   : hostBucket,
        // response
        statusCode: 204,
        extractBody : 'none',
    },

    DeleteBucketLifecycle : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html',
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

    DeleteBucketTagging : {
        url : '',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html',
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

    GetBucketTagging : {
        url : '',
        // request
        host : hostBucket,
        defaults : {
            tagging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            tagging : {
                required : true,
                type     : 'resource',
            },
        },
    },

    GetBucketLocation : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html',
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
            GrantRead : {
                name     : 'x-amz-grant-read',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWrite : {
                name     : 'x-amz-grant-write',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantReadAcp : {
                name     : 'x-amz-grant-read-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWriteAcp : {
                name     : 'x-amz-grant-write-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantFullControl : {
                name     : 'x-amz-grant-full-control',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
        },
        body : bodyLocationConstraint,
        // response
        extractBody : 'none',
    },

    PutBucketAcl : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html',
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
                required : false,
                type     : 'resource',
            },
            AccessControlPolicy : {
                required : false,
                type     : 'special',
                note     : 'A data structure which will be converted into a &lt;AccessControlPolicy&gt; XML document.',
            },
            Acl : {
                name     : 'x-amz-acl',
                required : false,
                type     : 'header',
                note     : 'Values: private, public-read, public-read-write, authenticated-read.',
            },
            GrantRead : {
                name     : 'x-amz-grant-read',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWrite : {
                name     : 'x-amz-grant-write',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantReadAcp : {
                name     : 'x-amz-grant-read-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWriteAcp : {
                name     : 'x-amz-grant-write-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantFullControl : {
                name     : 'x-amz-grant-full-control',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
        },
        body : bodyAccessControlPolicy,
        // response
        extractBody : 'none',
    },

    PutBucketLifecycle : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html',
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

    PutBucketTagging : {
        url : '',
        // request
        method : 'PUT',
        host : hostBucket,
        defaults : {
            tagging : undefined,
        },
        args : {
            BucketName : {
                required : true,
                type     : 'special',
            },
            tagging : {
                required : true,
                type     : 'resource',
            },
            Tags : {
                required : false,
                type     : 'special',
            },
            Event : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyTagging,
        addExtras : extrasContentMd5,
        // request
        statusCode : 204,
        extractBody : 'none',
    },

    PutBucketRequestPayment : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html',
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
            Range : {
                required : false,
                type     : 'header',
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
        statusCode: {
            '200' : true,
            '206' : true,
        },
    },

    GetObjectAcl : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html',
        // request
        method : 'HEAD',
        host : hostBucket,
        path : pathObject,
        args : {
            Range : {
                required : false,
                type     : 'header',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html',
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
            GrantRead : {
                name     : 'x-amz-grant-read',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWrite : {
                name     : 'x-amz-grant-write',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantReadAcp : {
                name     : 'x-amz-grant-read-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWriteAcp : {
                name     : 'x-amz-grant-write-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantFullControl : {
                name     : 'x-amz-grant-full-control',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html',
        // request
        method : 'PUT',
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
            GrantRead : {
                name     : 'x-amz-grant-read',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWrite : {
                name     : 'x-amz-grant-write',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantReadAcp : {
                name     : 'x-amz-grant-read-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWriteAcp : {
                name     : 'x-amz-grant-write-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantFullControl : {
                name     : 'x-amz-grant-full-control',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
        },
        body : bodyAccessControlPolicy,
        // response
        extractBody : 'none',
    },

    CopyObject : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html',
        // request
        method : 'PUT',
        host   : hostBucket,
        path   : pathObject,
        args : {
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
            Acl : {
                name : 'x-amz-acl',
                required : false,
                type : 'header',
            },
            GrantRead : {
                name     : 'x-amz-grant-read',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWrite : {
                name     : 'x-amz-grant-write',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantReadAcp : {
                name     : 'x-amz-grant-read-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantWriteAcp : {
                name     : 'x-amz-grant-write-acp',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
            GrantFullControl : {
                name     : 'x-amz-grant-full-control',
                required : false,
                type     : 'header',
                note     : 'A comma-separated list of one or more grantees (of the format type=value). Type must be emailAddress, id or url.',
            },
        },
        addExtras : extrasCopySource,
    },

    InitiateMultipartUpload : {
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html',
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
            ContentLength : {
                name     : 'Content-Length',
                required : true,
                type     : 'header',
            },
            Body : {
                required : true,
                type     : 'body',
            },
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html',
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
        url : 'http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html',
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
