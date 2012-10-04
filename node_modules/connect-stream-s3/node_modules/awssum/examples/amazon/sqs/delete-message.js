var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sqs = awssum.load('amazon/sqs').Sqs;

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
};

sqs.ReceiveMessage(options, function(err, data) {
    console.log("\nReceiving message from my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');

    // if there wasn't an error, delete the message
    if ( ! err ) {
        if ( data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message ) {
            options.ReceiptHandle = data.Body.ReceiveMessageResponse.ReceiveMessageResult.Message.ReceiptHandle;
            sqs.DeleteMessage(options, function(err, data) {
                console.log("\nDeleting Message - expecting success");
                inspect(err, 'Error');
                inspect(data, 'Data');
            });
        }
        else {
            console.log("\nNo messages to delete.");
        }
    }
});
