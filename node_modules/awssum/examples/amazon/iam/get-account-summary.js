var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Iam = awssum.load('amazon/iam').Iam;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var iam = new Iam({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', iam.region() );
fmt.field('EndPoint', iam.host() );
fmt.field('AccessKeyId', iam.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', iam.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', iam.awsAccountId() );

iam.GetAccountSummary(function(err, data) {
    fmt.msg("getting account summary - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
