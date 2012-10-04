var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sqs = awssum.load('amazon/sqs').Sqs;
var _ = require('underscore');

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
    MaxNumberOfMessages : 5,
};

sqs.ReceiveMessage(options, function(err, data) {
    var receiptHandles = [];
    var visibilityTimeouts = [];

    fmt.msg("Receiving message from my-queue - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');

    // if there wasn't an error, delete these messages in one hit
    if ( ! err ) {
        // make sure we have some messages to delete
        if ( _.isUndefined(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message) ) {
            fmt.msg("No messages to change visibility of");
            return;
        }

        if ( ! _.isArray(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message) ) {
            // turn this into an array
            data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message = [
                data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message
            ];
        }

        var batchOptions = {
            QueueName         : 'my-queue',
            Id                : [],
            ReceiptHandle     : [],
            VisibilityTimeout : [],
        };

        _.each(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message, function(m) {
            batchOptions.Id.push( 'id-' + Math.floor(Math.random() * 1000) );
            batchOptions.ReceiptHandle.push(m.ReceiptHandle);
            batchOptions.VisibilityTimeout.push(10);
        });

        sqs.ChangeMessageVisibilityBatch(batchOptions, function(err, data) {
            fmt.msg("Changing visibility batch - expecting success");
            fmt.dump(err, 'Error');
            fmt.dump(data, 'Data');
        });
    }
});
