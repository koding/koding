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
    BucketName : 'pie-18',
    ObjectName : 'test-object.txt',
};

s3.objectMetadata(options1, function(err, data) {
    fmt.msg("getting an object metadata from /pie-18/test-object.txt - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var options2 = {
    BucketName : 'pie-18',
    ObjectName : 'not-found.txt',
};

s3.objectMetadata(options2, function(err, data) {
    fmt.msg("getting missing object - expecting failure");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
