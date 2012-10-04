var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sts = awssum.load('amazon/sts').Sts;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sts = new Sts({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', sts.region() );
console.log( 'EndPoint :',  sts.host() );
console.log( 'AccessKeyId :', sts.accessKeyId() );
// console.log( 'SecretAccessKey :', sts.secretAccessKey() );
console.log( 'AwsAccountId :', sts.awsAccountId() );

sts.GetSessionToken(function(err, data) {
    console.log("\ngettting a session token - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
