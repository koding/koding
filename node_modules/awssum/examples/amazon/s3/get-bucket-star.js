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

s3.GetBucketAcl({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket acl");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketPolicy({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket policy - expecting failure, no policy exists");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketLocation({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket location");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketLogging({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket logging");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketNotification({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket notification");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketRequestPayment({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket request payment");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketVersioning({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket versioning");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketWebsite({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket website - expecting failure since this bucket has never had a website");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketTagging({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("get bucket tagging - expecting failure (NoSuchTagSetError)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.GetBucketTagging({ BucketName : 'pie-18' }, function(err, data) {
    fmt.msg("get bucket tagging - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

s3.ListMultipartUploads({ BucketName : 'pie-17' }, function(err, data) {
    fmt.msg("list multipart uploads - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
