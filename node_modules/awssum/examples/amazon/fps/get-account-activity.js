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

var opts1 = {
    StartDate    : '2012-01-01',
    EndDate      : (new Date()).toISOString().substr(0,10),
    MaxBatchSize : 100,
    Status       : 'Reserved',
};

fps.GetAccountActivity(opts1, function(err, data) {
    fmt.msg("getting the account activity - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var opts2 = {
    StartDate : '2012-01-01',
    Status    : 'InvalidStatus',
};

fps.GetAccountActivity(opts2, function(err, data) {
    fmt.msg("getting asctivity - expecting failure (invalid status)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
