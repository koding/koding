var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;
var _ = require('underscore');

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

var options1 = {
    BucketName : 'pie-17',
    MaxKeys : 4,
};

s3.ListObjects(options1, function(err, data) {
    console.log("\nlisting objects in this bucket - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');

    // check for error
    if ( err ) {
        console.log('Not doing another ListObjects since there was an error');
        return;
    }

    // now do a marker
    if ( data.Body.ListBucketResult.IsTruncated === 'true' ) {
        options1.Marker = _.last(data.Body.ListBucketResult.Contents).Key;

        s3.ListObjects(options1, function(err, data) {
            console.log("\ngetting the next set - expecting success");
            inspect(err, 'Error');
            inspect(data, 'Data');
        });
    }
});

var options2 = {
    BucketName : 'pie-17',
    MaxKeys : 4,
    Prefix : 'c',
};

s3.ListObjects(options2, function(err, data) {
    console.log("\nlisting object with a prefix - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
