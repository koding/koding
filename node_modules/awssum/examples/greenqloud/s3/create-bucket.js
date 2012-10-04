var fmt = require('fmt');
var awssum = require('awssum');
var greenqloud = awssum.load('greenqloud/greenqloud');
var S3 = awssum.load('greenqloud/s3').S3;

var env             = process.env;
var accessKeyId     = env.GREENQLOUD_ACCESS_KEY_ID;
var secretAccessKey = env.GREENQLOUD_SECRET_ACCESS_KEY;
var awsAccountId    = env.GREENQLOUD_ACCOUNT_ID;

var s3 = new S3({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : greenqloud.IS_1
});

fmt.field('Region', s3.region() );
fmt.field('EndPoint', s3.host() );
fmt.field('AccessKeyId', s3.accessKeyId() );
fmt.field('SecretAccessKey', s3.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', s3.awsAccountId() );

s3.CreateBucket({ BucketName : 'pie-19' }, function(err, data) {
    fmt.msg("creating pie-18 - expecting failure (already created)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
