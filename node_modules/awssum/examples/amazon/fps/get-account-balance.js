var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Fps = awssum.load('amazon/fps').Fps;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var fps = new Fps({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId'    : awsAccountId,
    'region'          : 'FPS-SANDBOX'
});

fmt.field('Region', fps.region() );
fmt.field('EndPoint', fps.host() );
fmt.field('AccessKeyId', fps.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', fps.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', fps.awsAccountId() );

fps.GetAccountBalance(function(err, data) {
    fmt.msg("getting the account balance - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
