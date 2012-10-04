var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', s3.region() );
fmt.field('EndPoint', s3.host() );
fmt.field('AccessKeyId', s3.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', s3.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', s3.awsAccountId() );

var options1 = {
    BucketName : 'pie-19',
};

s3.PutBucket(options1, function(err, data) {
    fmt.msg("putting bucket pie-19 - expecting failure (already created)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var options2 = {
    BucketName : 'pie-20',
    Acl : 'private',
};

s3.PutBucket(options2, function(err, data) {
    fmt.msg("putting bucket pie-20 with acl - expecting failure (already created)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
