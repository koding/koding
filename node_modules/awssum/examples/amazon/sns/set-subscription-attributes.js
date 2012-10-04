var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Sns = awssum.load('amazon/sns').Sns;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sns = new Sns({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', sns.region() );
fmt.field('EndPoint', sns.host() );
fmt.field('AccessKeyId', sns.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', sns.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', sns.awsAccountId() );

var data = {
    SubscriptionArn : 'invalid-arnsubscription-arn',
    AttributeName   : 'DeliveryPolicy',
    AttributeValue  : '{}',
};

// firstly, re-create this topic (it's idempotent) to get the topicArn
sns.SetSubscriptionAttributes(data, function(err, data) {
    fmt.msg("setting subscription attributes - expecting failure (invalid SubscriptionArn)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
