var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Emr = awssum.load('amazon/emr').Emr;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var emr = new Emr({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', emr.region() );
fmt.field('EndPoint', emr.host() );
fmt.field('AccessKeyId', emr.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', emr.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', emr.awsAccountId() );

emr.DescribeJobFlows(function(err, data) {
    fmt.msg("describing job flows - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

emr.DescribeJobFlows({
    JobFlowStates  : [ 'RUNNING', 'STARTING' ],
}, function(err, data) {
    fmt.msg("describing job flows (RUNNING, STARTING) - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

emr.DescribeJobFlows({
    JobFlowStates  : [ 'PENDING', 'STARTING' ],
}, function(err, data) {
    fmt.msg("describing job flows (PENDING, STARTING) - expecting failure (invalid PENDING) state");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
