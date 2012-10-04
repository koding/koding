var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

console.log( 'Region :', s3.region() );
console.log( 'EndPoint :',  s3.host() );
console.log( 'AccessKeyId :', s3.accessKeyId() );
// console.log( 'SecretAccessKey :', s3.secretAccessKey() );
console.log( 'AwsAccountId :', s3.awsAccountId() );

s3.GetBucketAcl({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket acl");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketPolicy({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket policy - expecting failure, no policy exists");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketLocation({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket location");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketLogging({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket logging");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketNotification({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket notification");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketRequestPayment({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket request payment");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketVersioning({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket versioning");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.GetBucketWebsite({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nget bucket website - expecting failure since this bucket has never had a website");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3.ListMultipartUploads({ BucketName : 'pie-17' }, function(err, data) {
    console.log("\nlist multipart uploads - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
