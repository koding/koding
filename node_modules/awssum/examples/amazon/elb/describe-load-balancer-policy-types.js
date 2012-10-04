var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Elb = awssum.load('amazon/elb').Elb;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var elb = new Elb({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', elb.region() );
fmt.field('EndPoint', elb.host() );
fmt.field('AccessKeyId', elb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', elb.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', elb.awsAccountId() );

elb.DescribeLoadBalancerPolicyTypes(function(err, data) {
    fmt.msg("describing load balancer policy types - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
