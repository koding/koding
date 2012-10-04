var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Glacier = awssum.load('amazon/glacier').Glacier;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var glacier = new Glacier({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId'    : awsAccountId, // required
    'region'          : amazon.US_EAST_1
});

fmt.field('Region',          glacier.region()                              );
fmt.field('EndPoint',        glacier.host()                                );
fmt.field('AccessKeyId',     glacier.accessKeyId().substr(0,3) + '...'     );
fmt.field('SecretAccessKey', glacier.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId',    glacier.awsAccountId()                        );

glacier.DescribeVault({ VaultName : 'test' }, function(err, data) {
    fmt.msg("describing vault - expecting failure (does not exist)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
