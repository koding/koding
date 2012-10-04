var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var CloudFormation = awssum.load('amazon/cloudformation').CloudFormation;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var cloudformation = new CloudFormation({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', cloudformation.region() );
fmt.field('EndPoint', cloudformation.host() );
fmt.field('AccessKeyId', cloudformation.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', cloudformation.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', cloudformation.awsAccountId() );

cloudformation.ListStacks(function(err, data) {
    fmt.msg("listing stacks - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
