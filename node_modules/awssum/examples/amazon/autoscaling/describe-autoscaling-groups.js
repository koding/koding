var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var AutoScaling = awssum.load('amazon/autoscaling').AutoScaling;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var as = new AutoScaling({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region'          : amazon.US_EAST_1,
});

fmt.field('Region', as.region() );
fmt.field('EndPoint', as.host() );
fmt.field('AccessKeyId', as.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', as.secretAccessKey().substr(0, 3) + '...' );

as.DescribeAutoScalingGroups(function(err, data) {
    fmt.msg("describing autoscaling groups - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
