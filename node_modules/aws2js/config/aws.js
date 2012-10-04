'use strict';

/**
 * Common suffix for the API endpoints
 */
exports.suffix = '.amazonaws.com';

/**
 * The supported regions. The values patch the SNAFU of the S3 API.
 */
exports.regions = {
	'us-east-1': '', // Virginia
	'us-west-1': 'us-west-1', // N. California
	'us-west-2': 'us-west-2', // Oregon
	'eu-west-1': 'EU', // Ireland
	'ap-southeast-1': 'ap-southeast-1', // Singapore
	'ap-northeast-1': 'ap-northeast-1', // Tokyo,
	'sa-east-1': 'sa-east-1' // Sao Paulo
};

/**
 * Services without region support and default endpoints
 */
exports.noRegion = {
	s3: null, // S3 sets the region per bucket when the bucket is created
	email: null,
	iam: null,
	elasticache: null,
	sts: null
};

/**
 * The S3 subresources that must be part of the signed string
 */
exports.subResource = {
	'acl': null,
	'lifecycle': null,
	'location': null,
	'logging': null,
	'notification': null,
	'partNumber': null,
	'policy': null,
	'requestPayment': null,
	'torrent': null,
	'uploadId': null,
	'uploads': null,
	'versionId': null,
	'versioning': null,
	'versions': null,
	'website': null,
	'delete': null
};

/**
 * Canned ACLs
 */
exports.cannedAcls = {
	'private' : null,
	'public-read' : null,
	'public-read-write' : null,
	'authenticated-read' : null,
	'bucket-owner-read' : null,
	'bucket-owner-full-control' : null
};

/**
 * The AWS clients with the default config. Loaded on demand by aws.js's load() method.
 */
exports.clients = {
	ec2: {
		prefix: 'ec2',
	    query: {
			Version: '2012-07-20',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
	    }
	},
	rds: {
		prefix: 'rds',
		query: {
			Version: '2012-07-31',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	ses: {
		prefix: 'email',
		host: 'email.us-east-1.amazonaws.com',
		signHeader: true,
		query: {
			Version: '2010-12-01'
		}
	},
	elb: {
		prefix: 'elasticloadbalancing',
		query: {
			Version: '2012-06-01',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	s3: {
		prefix: 's3'
	},
	iam: {
		prefix: 'iam',
		host: 'iam.amazonaws.com',
		query: {
			Version: '2010-05-08',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	autoscaling: {
		prefix: 'autoscaling',
		host: 'autoscaling.us-east-1.amazonaws.com',
		query: {
			Version: '2011-01-01',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	cloudwatch: {
		prefix: 'monitoring',
		query: {
			Version: '2010-08-01',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	elasticache: {
		prefix: 'elasticache',
		host: 'elasticache.us-east-1.amazonaws.com',
		query: {
			Version: '2012-03-09',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	sqs: {
		prefix: 'sqs',
		host: 'queue.amazonaws.com',
		query: {
			Version: '2011-10-01',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	cloudformation : {
		prefix: 'cloudformation',
		host: 'cloudformation.us-east-1.amazonaws.com',
		query: {
			Version: '2010-05-15',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	sdb: {
		prefix: 'sdb',
		query: {
			Version: '2009-04-15',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	dynamodb: {
		prefix: 'dynamodb',
		host: 'dynamodb.us-east-1.amazonaws.com',
		signHeader: true,
		query: {
			Version: '2011-12-05'
		}
	},
	sts: {
		prefix: 'sts',
		host: 'sts.amazonaws.com',
		query: {
			Version: '2011-06-15',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	sns: {
		prefix: 'sns',
		host: 'sns.us-east-1.amazonaws.com',
		query: {
			Version: '2010-03-31',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	},
	emr: {
		prefix: 'elasticmapreduce',
		host: 'elasticmapreduce.us-east-1.amazonaws.com',
		query: {
			Version: '2009-03-31',
			SignatureMethod: 'HmacSHA256',
			SignatureVersion: '2'
		}
	}
};
