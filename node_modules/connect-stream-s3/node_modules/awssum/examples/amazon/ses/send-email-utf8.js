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

var data = {
    ToAddresses : [
        'andychilton@gmail.com',
    ],
    Text : 'This is the text body with stuff like ç, é and ☺',
    Html : '<p>This is the HTML body with stuff like ç, é and ☺</p>',
    Subject : 'This is the subject with stuff like ç, é and ☺',
    Source : 'andychilton@gmail.com',
};

ses.SendEmail(data, function(err, data) {
    console.log("\nsending a UTF8 email - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
