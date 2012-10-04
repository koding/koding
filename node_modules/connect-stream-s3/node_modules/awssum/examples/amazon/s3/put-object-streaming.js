var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;
var fs = require('fs');

var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;
var bucket = process.env.S3_BUCKET;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

console.log( 'Region :', s3.region() );
console.log( 'EndPoint :',  s3.host() );
console.log( 'AccessKeyId :', s3.accessKeyId() );
// console.log( 'SecretAccessKey :', s3.secretAccessKey().substr(0,3) + "..." );
console.log( 'AwsAccountId :', s3.awsAccountId() );

// you must run fs.stat to get the file size for the content-length header (s3 requires this)
fs.stat(__filename, function(err, file_info) {
    if (err) {
        inspect(err, 'Error reading file');
        return;
    }

    var bodyStream = fs.createReadStream( __filename );

    console.log(__filename);
    console.log(file_info.size);

    var options = {
        BucketName    : 'pie-18',
        ObjectName    : __filename,
        ContentLength : file_info.size,
        Body          : bodyStream
    };

    s3.PutObject(options, function(err, data) {
        console.log("\nputting an object to " + bucket + " - expecting success");
        inspect(err, 'Error');
        inspect(data, 'Data');
    });
});
