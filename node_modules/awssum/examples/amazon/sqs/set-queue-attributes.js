var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sqs = awssum.load('amazon/sqs').Sqs;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sqs = new Sqs({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', sqs.region() );
fmt.field('EndPoint', sqs.host() );
fmt.field('AccessKeyId', sqs.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', sqs.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', sqs.awsAccountId() );

var options = {
    QueueName : 'my-queue',
};

sqs.SetQueueAttributes(options, function(err, data) {
    fmt.msg("Setting empty attributes for my-queue - expecting failure");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

options.AttributeName  = 'VisibilityTimeout';
options.AttributeValue = 30;

sqs.SetQueueAttributes(options, function(err, data) {
    fmt.msg("Setting VisibilityTimeout for my-queue - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
