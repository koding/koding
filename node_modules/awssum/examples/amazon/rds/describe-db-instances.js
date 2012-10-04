var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Rds = awssum.load('amazon/rds').Rds;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var rds = new Rds({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', rds.region() );
fmt.field('EndPoint', rds.host() );
fmt.field('AccessKeyId', rds.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', rds.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', rds.awsAccountId() );

rds.DescribeDBInstances(function(err, data) {
    fmt.msg("describing db instances - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
