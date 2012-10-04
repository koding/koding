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

var opts = {
    TransactionId : '12345678901234567890123456789012345',
    Description   : 'Cancelling because something did not work.',
};

fps.Cancel(opts, function(err, data) {
    fmt.msg("cancel - expecting failure (invalid transaction id)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
