var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var CloudFront = awssum.load('amazon/cloudfront').CloudFront;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var cloudFront = new CloudFront({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

console.log( 'Region :', cloudFront.region() );
console.log( 'EndPoint :',  cloudFront.host() );
console.log( 'AccessKeyId :', cloudFront.accessKeyId() );
// console.log( 'SecretAccessKey :', cloudFront.secretAccessKey() );
console.log( 'AwsAccountId :', cloudFront.awsAccountId() );

var data = {
    S3OriginDnsName : 'mybucket.s3.amazonaws.com',
    S3OriginOriginAccessIdentity : 'origin-access-identity/cloudfront/E127EXAMPLE51Z',
    CallerReference : 'your unique caller reference',
    Cname : 'mysite.example.com',
    Comment : 'My comments',
    Enabled : 'true',
    LoggingBucket : 'mylogs.s3.amazonaws.com',
    LoggingPrefix : 'myprefix/',
    TrustedSignersSelf : 1,
    TrustedSignersAwsAccountNumber : [ '123499998765', '098711114567' ],
};

cloudFront.CreateStreamingDistribution(data, function(err, data) {
    console.log("\ncreating a streaming distribution - expecting failure for tonnes of reasons");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
