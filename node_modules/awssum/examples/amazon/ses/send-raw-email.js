var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Ses = awssum.load('amazon/ses').Ses;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var ses = new Ses({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
});

fmt.field('Region', ses.region() );
fmt.field('EndPoint', ses.host() );
fmt.field('AccessKeyId', ses.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', ses.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', ses.awsAccountId() );

var rawMessage = '';
rawMessage += "To: you@example.com\n";
rawMessage += "From: me@example.com\n";
rawMessage += "Subject: Hello, World!\n";
rawMessage += "\n";
rawMessage += "This is the body.\n";

ses.SendRawEmail({ RawMessage : rawMessage }, function(err, data) {
    fmt.msg("sending a raw email - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
