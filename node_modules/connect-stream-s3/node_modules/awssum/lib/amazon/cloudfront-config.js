// --------------------------------------------------------------------------------------------------------------------
//
// cloudfront-config.js - class for AWS CloudFront
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

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/Actions_Dist.html
//
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateDistribution.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListDistributions.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetDistribution.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteDistribution.html

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/Actions_StreamingDist.html
//
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateStreamingDistribution.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListStreamingDistributions.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetStreamingDistribution.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetStreamingDistConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutStreamingDistConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteStreamingDistribution.html

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/Actions_OAI.html
//
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateOAI.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListOAIs.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetOAI.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetOAIConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/PutOAIConfig.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DeleteOAI.html

// From: http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/Actions_Invalidations.html
//
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateInvalidation.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/ListInvalidation.html
// * http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/GetInvalidation.html

module.exports = {

    // Operations on Distributions

    CreateDistribution : {
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
        path : pathDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetDistributionConfig : {
        path : pathDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutDistributionConfig : {
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
        path : pathStreamingDistributionId,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetStreamingDistributionConfig : {
        path : pathStreamingDistributionIdConfig,
        args : {
            DistributionId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutStreamingDistributionConfig : {
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
        path : pathOaiId,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
        },
    },

    GetOaiConfig : {
        path : pathOaiIdConfig,
        args : {
            OriginAccessId : {
                required : true,
                type     : 'special',
            },
        },
    },

    PutOaiConfig : {
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
        body : function(args) {
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
