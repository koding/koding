var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var s3 = new S3({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region'          : amazon.US_EAST_1,
});

fmt.line();
fmt.title('s3.ListBuckets');

fmt.field('Region',          s3.region());
fmt.field('EndPoint',        s3.host() );
fmt.field('AccessKeyId',     s3.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', s3.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId',    s3.awsAccountId() );

fmt.line();

s3.ListBuckets(function(err, data) {
    fmt.msg("listing all the buckets (no options given) - expecting success");
    fmt.dump(err,  'Error');
    fmt.dump(data, 'Data');
    fmt.line();
});

s3.ListBuckets({}, function(err, data) {
    fmt.msg("listing all the buckets (empty options) - expecting success");
    fmt.dump(err,  'Error');
    fmt.dump(data, 'Data');
    fmt.line();
});

s3.ListBuckets({ Ignored : 'this is' }, function(err, data) {
    fmt.msg("listing all the buckets (nothing interesting in options) - expecting success");
    fmt.dump(err,  'Error');
    fmt.dump(data, 'Data');
    fmt.line();
});
