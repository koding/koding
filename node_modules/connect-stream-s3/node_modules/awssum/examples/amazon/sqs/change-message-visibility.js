var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sqs = awssum.load('amazon/sqs').Sqs;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sqs = new Sqs({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

console.log( 'Region :', sqs.region() );
console.log( 'EndPoint :',  sqs.host() );
console.log( 'AccessKeyId :', sqs.accessKeyId() );
// console.log( 'SecretAccessKey :', sqs.secretAccessKey() );
console.log( 'AwsAccountId :', sqs.awsAccountId() );

var options = {
    queueName : 'my-queue',
};

sqs.receiveMessage(options, function(err, data) {
    console.log("\nReceiving message from my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');

    // if there wasn't an error, let's try and change the visibility of this message
    if ( ! err ) {
        var receiptHandle = data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message.ReceiptHandle;

        var visibilityOptions = {
            queueName         : 'my-queue',
            receiptHandle     : receiptHandle,
            visibilityTimeout : 10,
        };

        sqs.changeMessageVisibility(visibilityOptions, function(err, data) {
            console.log("\nChanging message visibility - expecting success");
            inspect(err, 'Error');
            inspect(data, 'Data');
        });
    }
});
