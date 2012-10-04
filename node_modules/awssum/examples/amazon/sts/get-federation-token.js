var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sts = awssum.load('amazon/sts').Sts;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sts = new Sts({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', sts.region() );
fmt.field('EndPoint', sts.host() );
fmt.field('AccessKeyId', sts.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', sts.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', sts.awsAccountId() );

sts.GetFederationToken({ Name : 'chilts' }, function(err, data) {
    fmt.msg("getting a federation token - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
