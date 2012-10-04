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
    QueueName : 'my-queue'
};

options.AttributeName = 'All';
sqs.GetQueueAttributes(options, function(err, data) {
    console.log("\nGetting all attributes for my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

options.AttributeName = [ 'ApproximateNumberOfMessages', 'MessageRetentionPeriod' ];
sqs.GetQueueAttributes(options, function(err, data) {
    console.log("\nGetting 2 attrs (using an array) for my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

options.AttributeName = [ 'ApproximateNumberOfMessages', 'MessageRetentionPeriod', 'DelaySeconds' ];
sqs.GetQueueAttributes(options, function(err, data) {
    console.log("\nGetting 2 attrs (using an array) for my-queue - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
