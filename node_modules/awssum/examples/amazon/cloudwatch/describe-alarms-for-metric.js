var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var CloudWatch = awssum.load('amazon/cloudwatch').CloudWatch;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var cloudwatch = new CloudWatch({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId'    : awsAccountId,
    'region'          : amazon.US_EAST_1,
});

fmt.field('Region', cloudwatch.region() );
fmt.field('EndPoint', cloudwatch.host() );
fmt.field('AccessKeyId', cloudwatch.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', cloudwatch.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', cloudwatch.awsAccountId() );

var opts = {
    MetricName : 'ConsumedReadCapacityUnits',
    Namespace : 'AWS/DynamoDB',
    Dimensions : [
        { Name : 'TableName', Value : 'test', },
        { Name : 'TableName', Value : 'test-tweets', },
    ],
    Unit : 'Count',
};

cloudwatch.DescribeAlarmsForMetric(opts, function(err, data) {
    fmt.msg("describing alarms for metric - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
