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

fmt.line();
fmt.title('ec2.DescribeInstances');

fmt.field('Region', ec2.region() );
fmt.field('EndPoint', ec2.host() );
fmt.field('AccessKeyId', ec2.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', ec2.secretAccessKey().substr(0,3) + '...' );
fmt.field('AwsAccountId', ec2.awsAccountId() );

fmt.line();

ec2.DescribeInstances(function(err, data) {
    fmt.msg("Describing instances - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
    fmt.line();
});

var args = {
    Filter : [
        {
            Name : 'availability-zone',
            Value : [ 'us-east-1', 'us-west-1' ],
        },
        {
            Name : 'instance-id',
            Value : [ 'i-7a00642e' ],
        },
    ],
};

ec2.DescribeInstances(args, function(err, data) {
    fmt.msg("Describing instances (with filter) - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
    fmt.line();
});
