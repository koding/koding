// --------------------------------------------------------------------------------------------------------------------
//
// cloudfront-config.js - config for AWS CloudFront
//
// Copyright (c) 2011 AppsAttic Ltd - http://www.appsattic.com/
// Written by Andrew Chilton <chilts@appsattic.com>
//
// License: http://opensource.org/licenses/MIT
//
// --------------------------------------------------------------------------------------------------------------------

var data2xml = require('data2xml');

// --------------------------------------------------------------------------------------------------------------------

function pathDistribution(options, args) {
    return '/' + this.version() + '/distribution';
}

function pathDistributionId(options, args) {
    return '/' + this.version() + '/distribution/' + args.DistributionId;
}

function pathDistributionIdConfig(options, args) {
    return '/' + this.version() + '/distribution/' + args.DistributionId + '/config';
}

function pathDistributionInvalidation(options, args) {
    return '/' + this.version() + '/distribution/' + args.DistributionId + '/invalidation';
}

function pathDistributionInvalidationId(options, args) {
    return '/' + this.version() + '/distribution/' + args.DistributionId + '/invalidation/' + args.InvalidationId;
}

function pathStreamingDistribution(options, args) {
    return '/' + this.version() + '/streaming-distribution';
}

function pathStreamingDistributionId(options, args) {
    return '/' + this.version() + '/streaming-distribution/' + args.DistributionId;
}

function pathStreamingDistributionIdConfig(options, args) {
    return '/' + this.version() + '/streaming-distribution/' + args.DistributionId + '/config';
}

function pathOai(options, args) {
    return '/' + this.version() + '/origin-access-identity/cloudfront';
}

function pathOaiId(options, args) {
    return '/' + this.version() + '/origin-access-identity/cloudfront/' + args.OriginAccessId;
}

function pathOaiIdConfig(options, args) {
    return '/' + this.version() + '/origin-access-identity/cloudfront/' + args.OriginAccessId + '/config';
}

function bodyDistributionConfig(options, args) {
    // create the XML
    var data = {
        _attr : { 'xmlns' : 'http://cloudfront.amazonaws.com/doc/2010-11-01/' },
    };

    if ( args.S3OriginDnsName ) {
        data.S3Origin = {};
        data.S3Origin.DNSName = args.S3OriginDnsName;
        if ( args.S3OriginOriginAccessIdentity ) {
            data.S3Origin.OriginAccessIdentity = args.S3OriginOriginAccessIdentity;
        }
    }

    if ( args.CustomOriginDnsName || args.CustomOriginOriginProtocolPolicy  ) {
        data.CustomOrigin = {};
        if ( args.CustomOriginDnsName ) {
            data.CustomOrigin.DNSName = args.CustomOriginDnsName;
        }
        if ( args.CustomOriginHttpPort ) {
            data.CustomOrigin.HTTPPort = args.CustomOriginHttpPort;
        }
        if ( args.CustomOriginHttpsPort ) {
            data.CustomOrigin.HTTPSPort = args.CustomOriginHttpsPort;
        }
        if ( args.CustomOriginOriginProtocolPolicy ) {
            data.CustomOrigin.OriginProtocolPolicy = args.CustomOriginOriginProtocolPolicy;
        }
    }

    data.CallerReference = args.CallerReference;

    if ( args.Cname ) {
        data.CNAME = args.Cname;
    }

    if ( args.Comment ) {
        data.Comment = args.Comment;
    }

    if ( args.DefaultRootObject ) {
        data.DefaultRootObject = args.DefaultRootObject;
    }

    data.Enabled = args.Enabled;

    if ( args.LoggingBucket ) {
        data.Logging = {};
        data.Logging.Bucket = args.LoggingBucket;
        if ( args.LoggingPrefix ) {
            data.Logging.Prefix = args.LoggingPrefix;
        }
    }

    if ( args.TrustedSignersSelf || args.TrustedSignersAwsAccountNumber ) {
        data.TrustedSigners = {};
        if ( args.TrustedSignersSelf ) {
            data.TrustedSigners.Self = '';
        }
        if ( args.TrustedSignersAwsAccountNumber ) {
            data.TrustedSigners.AwsAccountNumber = args.TrustedSignersAwsAccountNumber;
        }
    }

    if ( args.RequiredProtocolsProtocol ) {
        data.RequiredProtocols = {};
        data.RequiredProtocols.Protocol = args.RequiredProtocolsProtocol;
    }

    return data2xml('DistributionConfig', data);
}

function bodyStreamingDistributionConfig(options, args) {
    // create the XML
    var data = {
        _attr : { 'xmlns' : 'http://cloudfront.amazonaws.com/doc/2010-11-01/' },
    };

    if ( args.S3OriginDnsName ) {
        data.S3Origin = {};
        data.S3Origin.DNSName = args.S3OriginDnsName;
        if ( args.S3OriginOriginAccessIdentity ) {
            data.S3Origin.OriginAccessIdentity = args.S3OriginOriginAccessIdentity;
        }
    }

    data.CallerReference = args.CallerReference;

    if ( args.Cname ) {
        data.CNAME = args.Cname;
    }

    if ( args.Comment ) {
        data.Comment = args.Comment;
    }

    data.Enabled = args.Enabled;

    if ( args.LoggingBucket ) {
        data.Logging = {};
        data.Logging.Bucket = args.LoggingBucket;
        if ( args.LoggingPrefix ) {
            data.Logging.Prefix = args.LoggingPrefix;
        }
    }

    if ( args.TrustedSignersSelf || args.TrustedSignersAwsAccountNumber ) {
        data.TrustedSigners = {};
        if ( args.TrustedSignersSelf ) {
            data.TrustedSigners.Self = '';
        }
        if ( args.TrustedSignersAwsAccountNumber ) {
            data.TrustedSigners.AwsAccountNumber = args.TrustedSignersAwsAccountNumber;
        }

    }

    return data2xml('StreamingDistributionConfig', data);
}

function bodyOaiConfig(options, args) {
    var self = this;

    var data = {
        _attr : { xmlns : 'http://cloudfront.amazonaws.com/doc/2010-11-01/', },
        CallerReference : args.CallerReference,
    };

    if ( args.Comments ) {
        data.Comments = args.Comments;
    }

    return data2xml('CloudFrontOriginAccessIdentityConfig', data);
}

// --------------------------------------------------------------------------------------------------------------------

module.exports = {

    // Operations on Distributions

    CreateDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateDistribution.html',
        method : 'POST',
        path : pathDistribution,
        args : {
            // S3Origin Elements
            DnsName : {
                type : 'special',
                required : false,
            },
            OriginAccessIdentity : {
                type : 'special',
                required : false,
            },
            // CustomOrigin elements
            CustomOriginDnsName : {
                type : 'special',
                required : false,
            },
            CustomOriginHttpPort : {
                type : 'special',
                required : false,
            },
            CustomOriginHttpsPort : {
                type : 'special',
                required : false,
            },
            CustomOriginOriginProtocolPolicy : {
                type : 'special',
                required : false,
            },
            // other top level elements
            CallerReference : {
                type : 'special',
                required : true,
            },
            Cname : {
                type : 'special',
                required : false,
            },
            Comment : {
                type : 'special',
                required : false,
            },
            Enabled : {
                type : 'special',
                required : true,
            },
            DefaultRootObject : {
                type : 'special',
                required : true,
            },
            // Logging Elements
            LoggingBucket : {
                type : 'special',
                required : false,
            },
            LoggingPrefix : {
                type : 'special',
                required : false,
            },
            // TrustedSigners Elements
            TrustedSignersSelf : {
                type : 'special',
                required : false,
            },
            TrustedSignersAwsAccountNumber : {
                type : 'special',
                required : false,
            },
            RequiredProtocols : {
                type : 'special',
                required : false,
            },
        },
        body : bodyDistributionConfig,
        statusCode: 201,
    },

    ListDistributions : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListDistributions.html',
        path : pathDistribution,
        args : {
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetDistribution.html',
        path : pathDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetDistributionConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetConfig.html',
        path : pathDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutDistributionConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutConfig.html',
        method : 'PUT',
        path : pathDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            IfMatch : {
                required : true,
                type     : 'header'
            },
            // S3Origin Elements
            DnsName : {
                type : 'special',
                required : false,
            },
            OriginAccessIdentity : {
                type : 'special',
                required : false,
            },
            // CustomOrigin elements
            CustomOriginDnsName : {
                type : 'special',
                required : false,
            },
            CustomOriginHttpPort : {
                type : 'special',
                required : false,
            },
            CustomOriginHttpsPort : {
                type : 'special',
                required : false,
            },
            CustomOriginOriginProtocolPolicy : {
                type : 'special',
                required : false,
            },
            // other top level elements
            CallerReference : {
                type : 'special',
                required : true,
            },
            Cname : {
                type : 'special',
                required : false,
            },
            Comment : {
                type : 'special',
                required : false,
            },
            Enabled : {
                type : 'special',
                required : true,
            },
            DefaultRootObject : {
                type : 'special',
                required : true,
            },
            // Logging Elements
            LoggingBucket : {
                type : 'special',
                required : false,
            },
            LoggingPrefix : {
                type : 'special',
                required : false,
            },
            // TrustedSigners Elements
            TrustedSignersSelf : {
                type : 'special',
                required : false,
            },
            TrustedSignersAwsAccountNumber : {
                type : 'special',
                required : false,
            },
            RequiredProtocols : {
                type : 'special',
                required : false,
            },
        },
        body : bodyDistributionConfig,
    },

    DeleteDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteDistribution.html',
        method : 'DELETE',
        path : pathDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            IfMatch : {
                required : true,
                type     : 'header'
            },
        },
        statusCode : 204,
    },

    // Operations on Streaming Distributions

    CreateStreamingDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateStreamingDistribution.html',
        method : 'POST',
        path : pathStreamingDistribution,
        args : {
            // S3Origin Elements
            S3OriginDnsName : {
                type : 'special',
                required : false,
            },
            S3OriginOriginAccessIdentity : {
                type : 'special',
                required : false,
            },
            // other top level elements
            CallerReference : {
                type : 'special',
                required : true,
            },
            Cname : {
                type : 'special',
                required : false,
            },
            Comment : {
                type : 'special',
                required : false,
            },
            Enabled : {
                type : 'special',
                required : true,
            },
            // Logging Elements
            LoggingBucket : {
                type : 'special',
                required : false,
            },
            LoggingPrefix : {
                type : 'special',
                required : false,
            },
            // TrustedSigners Elements
            TrustedSignersSelf : {
                type : 'special',
                required : false,
            },
            TrustedSignersAwsAccountNumber : {
                type : 'special',
                required : false,
            },
        },
        body : bodyStreamingDistributionConfig,
    },

    ListStreamingDistributions : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListStreamingDistributions.html',
        path : pathStreamingDistribution,
        args : {
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetStreamingDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetStreamingDistribution.html',
        path : pathStreamingDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetStreamingDistributionConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetStreamingDistConfig.html',
        path : pathStreamingDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutStreamingDistributionConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutStreamingDistConfig.html',
        method : 'PUT',
        path : pathStreamingDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            IfMatch : {
                required : true,
                type     : 'header'
            },
            // S3Origin Elements
            DnsName : {
                type : 'special',
                required : false,
            },
            OriginAccessIdentity : {
                type : 'special',
                required : false,
            },
            // other top level elements
            CallerReference : {
                type : 'special',
                required : true,
            },
            Cname : {
                type : 'special',
                required : false,
            },
            Comment : {
                type : 'special',
                required : false,
            },
            Enabled : {
                type : 'special',
                required : true,
            },
            // Logging Elements
            LoggingBucket : {
                type : 'special',
                required : false,
            },
            LoggingPrefix : {
                type : 'special',
                required : false,
            },
            // TrustedSigners Elements
            TrustedSignersSelf : {
                type : 'special',
                required : false,
            },
            TrustedSignersAwsAccountNumber : {
                type : 'special',
                required : false,
            },
        },
        body : bodyStreamingDistributionConfig,
    },

    DeleteStreamingDistribution : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteStreamingDistribution.html',
        method : 'DELETE',
        path : pathStreamingDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            IfMatch : {
                required : true,
                type     : 'header'
            },
        },
        statusCode : 204,
    },

    // Operations on Origin Access Identities

    CreateOai : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateOAI.html',
        method : 'POST',
        path : pathOai,
        args : {
            CallerReference : {
                required : true,
                type     : 'special',
            },
            Comment : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyOaiConfig,
        statusCode: 201,
    },

    ListOais : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListOAIs.html',
        path : pathOai,
        args : {
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetOai : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetOAI.html',
        path : pathOaiId,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetOaiConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetOAIConfig.html',
        path : pathOaiIdConfig,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutOaiConfig : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutOAIConfig.html',
        method : 'PUT',
        path : pathOai,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
            CallerReference : {
                required : true,
                type     : 'special',
            },
            Comment : {
                required : false,
                type     : 'special',
            },
        },
        body : bodyOaiConfig,
    },

    DeleteOai : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteOAI.html',
        method : 'DELETE',
        path : pathOaiId,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
            IfMatch : {
                required : true,
                type     : 'header'
            },
        },
        statusCode : 204,
    },

    // Operations on Invalidations

    CreateInvalidation : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateInvalidation.html',
        method : 'POST',
        path   : pathDistributionInvalidation,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            Path : {
                required : true,
                type     : 'special',
            },
            CallerReference : {
                required : false,
                type     : 'special',
            },
        },
        body : function(options, args) {
            var self = this;
            var data = {
                Path : args.Path,
            };
            if ( args.CallerReference ) {
                data.CallerReference = args.CallerReference;
            }
            return data2xml('InvalidationBatch', data);
        },
    },

    ListInvalidations : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListInvalidation.html',
        path : pathDistributionInvalidation,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

    GetInvalidation : {
        url : 'http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetInvalidation.html',
        path : pathDistributionInvalidationId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
            Marker : {
                required : false,
                type     : 'param',
            },
            MaxItems : {
                required : false,
                type     : 'param',
            },
        },
    },

};

// --------------------------------------------------------------------------------------------------------------------
