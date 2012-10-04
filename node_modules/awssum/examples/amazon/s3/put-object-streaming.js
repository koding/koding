var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;
var fs = require('fs');

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;
var bucket = process.env.S3_BUCKET;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', s3.region() );
fmt.field('EndPoint', s3.host() );
fmt.field('AccessKeyId', s3.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', s3.secretAccessKey().substr(0,3) + "...".substr(0, 3) + '...' );
fmt.field('AwsAccountId', s3.awsAccountId() );

// you must run fs.stat to get the file size for the content-length header (s3 requires this)
fs.stat(__filename, function(err, file_info) {
    if (err) {
        fmt.dump(err, 'Error reading file');
        return;
    }

    var bodyStream = fs.createReadStream( __filename );

    fmt.msg(__filename);
    fmt.msg(file_info.size);

    var options = {
        BucketName    : 'pie-18',
        ObjectName    : __filename,
        ContentLength : file_info.size,
        Body          : bodyStream
    };

    s3.PutObject(options, function(err, data) {
        fmt.msg("putting an object to " + bucket + " - expecting success");
        fmt.dump(err, 'Error');
        fmt.dump(data, 'Data');
    });
});
