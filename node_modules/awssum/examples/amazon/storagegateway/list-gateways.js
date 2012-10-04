var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var StorageGateway = awssum.load('amazon/storagegateway').StorageGateway;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sg = new StorageGateway({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', sg.region() );
fmt.field('EndPoint', sg.host() );
fmt.field('AccessKeyId', sg.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', sg.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', sg.awsAccountId() );

sg.ListGateways(function(err, data) {
    fmt.msg("listing gateways - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sg.ListGateways({ Limit : 5 }, function(err, data) {
    fmt.msg("listing gateways with a limit of 5 - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
