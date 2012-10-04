var inspect = require('eyes').inspector();
var amazon = require('amazon/amazon');
var S3 = require('amazon/s3').S3;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});
var s3eu = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.EU_WEST_1
});

console.log( 'Region :', s3.region() );
console.log( 'EndPoint :',  s3.host() );
console.log( 'AccessKeyId :', s3.accessKeyId() );
// console.log( 'SecretAccessKey :', s3.secretAccessKey() );
console.log( 'AwsAccountId :', s3.awsAccountId() );

s3.CreateBucket({ BucketName : 'pie-18' }, function(err, data) {
    console.log("\ncreating pie-18 - expecting failure (already created)");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

s3eu.CreateBucket({ BucketName : 'pie-18-in-europe' }, function(err, data) {
    console.log("\ncreating pie-18-in-europe - expecting failure (already created)");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
