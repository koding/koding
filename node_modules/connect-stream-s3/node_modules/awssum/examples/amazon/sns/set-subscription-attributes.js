var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sns = awssum.load('amazon/sns').Sns;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sns = new Sns({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', sns.region() );
console.log( 'EndPoint :',  sns.host() );
console.log( 'AccessKeyId :', sns.accessKeyId() );
// console.log( 'SecretAccessKey :', sns.secretAccessKey() );
console.log( 'AwsAccountId :', sns.awsAccountId() );

var data = {
    SubscriptionArn : 'invalid-arnsubscription-arn',
    AttributeName   : 'DeliveryPolicy',
    AttributeValue  : '{}',
};

// firstly, re-create this topic (it's idempotent) to get the topicArn
sns.SetSubscriptionAttributes(data, function(err, data) {
    console.log("\nsetting subscription attributes - expecting failure (invalid SubscriptionArn)");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
