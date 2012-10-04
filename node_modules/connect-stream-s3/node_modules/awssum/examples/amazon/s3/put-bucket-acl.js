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

var options = {
    BucketName         : 'pie-18',
    OwnerId            : 'chilts',
    DisplayName        : 'me@example.com',
    GranteeId          : 'chilts',
    GranteeDisplayName : 'you@example.com',
    Permission         : 'READ',
};

s3.PutBucketAcl(options, function(err, data) {
    console.log("\nputting bucket ACL pie-18 - expecting failure");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
