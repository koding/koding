var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Route53 = awssum.load('amazon/route53').Route53;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var r53 = new Route53({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
});

fmt.field('Region', r53.region() );
fmt.field('EndPoint', r53.host() );
fmt.field('AccessKeyId', r53.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', r53.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', r53.awsAccountId() );

r53.GetHostedZone({ HostedZoneId : 'deadbeef' }, function(err, data) {
    fmt.msg("getting hosted zone - expecting failure");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
