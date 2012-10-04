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

// from example on http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/DistributionConfigDatatype.html
var data = {
    S3OriginDnsName : 'mybucket.s3.amazonaws.com',
    S3OriginOriginAccessIdentity : 'origin-access-identity/cloudfront/E127EXAMPLE51Z',
    CustomOriginDnsName : 'www.example.com',
    CustomOriginHttpPort : '80',
    CustomOriginHttpsPort : '443',
    CustomOriginOriginProtocolPolicy : 'http-only',
    CallerReference : 'your unique caller reference',
    Cname : 'mysite.example.com',
    Comment : 'My comments',
    Enabled : 'true',
    DefaultRootObject : 'index.html',
    LoggingBucket : 'mylogs.s3.amazonaws.com',
    LoggingPrefix : 'myprefix/',
    TrustedSignersSelf : 1,
    TrustedSignersAwsAccountNumber : [ '123499998765', '098711114567' ],
    RequiredProtocolsProtocol : 'https'
};

cloudFront.CreateDistribution(data, function(err, data) {
    fmt.msg("creating a distribution - expecting failure for tonnes of reasons");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
