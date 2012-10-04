var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Ses = awssum.load('amazon/ses').Ses;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var ses = new Ses({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', ses.region() );
console.log( 'EndPoint :',  ses.host() );
console.log( 'AccessKeyId :', ses.accessKeyId() );
// console.log( 'SecretAccessKey :', ses.secretAccessKey() );
console.log( 'AwsAccountId :', ses.awsAccountId() );

var rawMessage = '';
rawMessage += "To: you@example.com\n";
rawMessage += "From: me@example.com\n";
rawMessage += "Subject: Hello, World!\n";
rawMessage += "\n";
rawMessage += "This is the body.\n";

ses.SendRawEmail({ RawMessage : rawMessage }, function(err, data) {
    console.log("\nsending a raw email - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
