var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Ec2 = awssum.load('amazon/ec2').Ec2;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var ec2 = new Ec2({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', ec2.region() );
fmt.field('EndPoint', ec2.host() );
fmt.field('AccessKeyId', ec2.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', ec2.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', ec2.awsAccountId() );

ec2.DescribeTags({ Filter : [ { Name : 'resource-type', Value : 'instance' } ]}, function(err, data) {
    fmt.msg("describing tags - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
