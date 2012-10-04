var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var ElastiCache = awssum.load('amazon/elasticache').ElastiCache;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var elastiCache = new ElastiCache({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', elastiCache.region() );
fmt.field('EndPoint', elastiCache.host() );
fmt.field('AccessKeyId', elastiCache.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', elastiCache.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', elastiCache.awsAccountId() );

elastiCache.DescribeCacheClusters(function(err, data) {
    fmt.msg("describing cache clusters - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
