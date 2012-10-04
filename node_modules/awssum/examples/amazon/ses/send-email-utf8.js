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
    fmt.msg("sending a UTF8 email - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
