var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var CloudFront = awssum.load('amazon/cloudfront').CloudFront;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var cloudFront = new CloudFront({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', cloudFront.region() );
fmt.field('EndPoint', cloudFront.host() );
fmt.field('AccessKeyId', cloudFront.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', cloudFront.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', cloudFront.awsAccountId() );

var data = {
    DistributionId : 'InvalidDistId',
    Path : [ '/path1', '/path2' ],
    CallerReference : 'Hello, World!',
};

cloudFront.CreateInvalidation(data, function(err, data) {
    fmt.msg("creating an invalidation - expecting failure due to distribution being invalid");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
