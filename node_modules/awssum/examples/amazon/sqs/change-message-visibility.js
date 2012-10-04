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
    queueName : 'my-queue',
};

sqs.receiveMessage(options, function(err, data) {
    fmt.msg("Receiving message from my-queue - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');

    // if there wasn't an error, let's try and change the visibility of this message
    if ( ! err ) {
        var receiptHandle = data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message.ReceiptHandle;

        var visibilityOptions = {
            queueName         : 'my-queue',
            receiptHandle     : receiptHandle,
            visibilityTimeout : 10,
        };

        sqs.changeMessageVisibility(visibilityOptions, function(err, data) {
            fmt.msg("Changing message visibility - expecting success");
            fmt.dump(err, 'Error');
            fmt.dump(data, 'Data');
        });
    }
});
