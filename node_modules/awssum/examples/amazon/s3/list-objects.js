var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;
var _ = require('underscore');

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
    BucketName : 'pie-17',
    MaxKeys : 4,
};

s3.ListObjects(options1, function(err, data) {
    fmt.msg("listing objects in this bucket - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');

    // check for error
    if ( err ) {
        fmt.msg('Not doing another ListObjects since there was an error');
        return;
    }

    // now do a marker
    if ( data.Body.ListBucketResult.IsTruncated === 'true' ) {
        options1.Marker = _.last(data.Body.ListBucketResult.Contents).Key;

        s3.ListObjects(options1, function(err, data) {
            fmt.msg("getting the next set - expecting success");
            fmt.dump(err, 'Error');
            fmt.dump(data, 'Data');
        });
    }
});

var options2 = {
    BucketName : 'pie-17',
    MaxKeys : 4,
    Prefix : 'c',
};

s3.ListObjects(options2, function(err, data) {
    fmt.msg("listing object with a prefix - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
