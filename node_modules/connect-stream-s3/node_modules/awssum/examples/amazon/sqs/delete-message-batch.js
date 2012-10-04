var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sqs = awssum.load('amazon/sqs').Sqs;
var _ = require('underscore');

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sqs = new Sqs(accessKeyId, secretAccessKey, awsAccountId, amazon.US_EAST_1);

console.log( 'Region :', sqs.region() );
console.log( 'EndPoint :',  sqs.host() );
console.log( 'AccessKeyId :', sqs.accessKeyId() );
// console.log( 'SecretAccessKey :', sqs.secretAccessKey() );
console.log( 'AwsAccountId :', sqs.awsAccountId() );

var options = {
    QueueName : 'my-queue',
    MaxNumberOfMessages : 5,
};

sqs.ReceiveMessage(options, function(err, data) {
    var msgs = [];
    var i = 1;

    console.log("\nReceiving message from my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');

    // if there wasn't an error, delete these messages in one hit
    if ( ! err ) {
        // make sure we have some messages to delete
        if ( _.isUndefined(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message) ) {
            console.log("\nNothing to delete");
            return;
        }

        if ( ! _.isArray(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message) ) {
            // turn this into an array
            data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message = [
                data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message
            ];
        }

        var options = {
            QueueName     : 'my-queue',
            ReceiptHandle : [],
            Id            : [],
        };

        _.each(data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message, function(m) {
            options.ReceiptHandle.push( m.ReceiptHandle );
            options.Id.push( Math.floor(Math.random() * 1000) );
        });

        sqs.DeleteMessageBatch(options, function(err, data) {
            console.log("\nDeleting Messages - expecting success");
            inspect(err, 'Error');
            inspect(data, 'Data');
        });
    }
});
