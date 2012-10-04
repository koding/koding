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
    QueueName : 'my-queue'
};

sqs.ReceiveMessage(options, function(err, data) {
    fmt.msg("Receiving message from my-queue - expecting success (and a message)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

options.AttributeName = 'All';
sqs.ReceiveMessage(options, function(err, data) {
    fmt.msg("Receiving message from my-queue - expecting success (and a message with all the trimmings)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

options.MaxNumberOfMessages = 3;
options.VisibilityTimeout = 10;
sqs.ReceiveMessage(options, function(err, data) {
    fmt.msg("Receiving 3 messages from my-queue - expecting success (with all the trimmings)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sqs.ReceiveMessage({ queueName : 'new-queue' }, function(err, data) {
    fmt.msg("Receiving message from new-queue - expecting success (but nothing)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
