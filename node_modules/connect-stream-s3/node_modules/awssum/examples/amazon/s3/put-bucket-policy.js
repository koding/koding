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
    BucketName   : 'pie-18',
    BucketPolicy : {
        'Version' : '2008-10-17',
        'Statement' : [
            {
                'Sid' : 'AddCannedAcl',
                'Effect' : 'Allow',
                'Principal' : {
                    'AWS' : [ 'arn:aws:iam::778695189650:root', 'arn:aws:iam::178784293420:root' ]
                },
                'Action' : [ 's3:PutObject', 's3:PutObjectAcl' ],
                'Resource' : [ 'arn:aws:s3:::bucket/*' ],
                'Condition' : {
                    'StringEquals' : {
                        's3:x-amz-acl' : [ 'public-read' ]
                    }
                }
            }
        ]
    }
};

s3.PutBucketPolicy(options, function(err, data) {
    console.log("\nputting bucket policy - expecting failure ('Invalid principal in policy')");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
