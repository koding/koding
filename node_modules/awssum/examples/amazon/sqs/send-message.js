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

var optionsMyQueue = {
    QueueName : 'my-queue',
    MessageBody : 'HelloWorld',
};

var optionsNewQueue = {
    QueueName : 'my-queue',
};

var optionsMyQueueDelayed = {
    QueueName    : 'my-queue',
    MessageBody  : 'HelloWorld',
    DelaySeconds : 10,
};

sqs.SendMessage(optionsMyQueue, function(err, data) {
    fmt.msg("Sending a message to a queue - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sqs.SendMessage(optionsNewQueue, function(err, data) {
    fmt.msg("Sending an undefined message - expecting failure");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sqs.SendMessage(optionsMyQueueDelayed, function(err, data) {
    fmt.msg("Sending a delayed message - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
