var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var ElastiCache = awssum.load('amazon/elasticache').ElastiCache;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var elastiCache = new ElastiCache({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', elastiCache.region() );
console.log( 'EndPoint :',  elastiCache.host() );
console.log( 'AccessKeyId :', elastiCache.accessKeyId() );
// console.log( 'SecretAccessKey :', elastiCache.secretAccessKey() );
console.log( 'AwsAccountId :', elastiCache.awsAccountId() );

var data = {
    CacheClusterId : 'Invalid ID',
    CacheNodeType : 'cache.m1.large',
    CacheSecurityGroupNames : [
        'default1',
        'default2'
    ],
    Engine : 'memcached',
    NumCacheNodes : 1,
};

elastiCache.CreateCacheCluster(data, function(err, data) {
    console.log("\ncreating a cache cluster - expecting failure since CacheClusterId is invalid");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
