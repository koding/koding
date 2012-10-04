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

// firstly, re-create this topic (it's idempotent) to get the topicArn
sns.CreateTopic({ Name : 'my-topic' }, function(err, data) {
    fmt.msg("Creating (my-topic) - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');

    // now call the addPermission()
    if ( ! err ) {
        var args = {
            TopicArn : data.CreateTopicResponse.CreateTopicResult.TopicArn,
            Label : 'A Test Permission',
            AwsAccountId : [ '123-456-789' ],
            ActionName : [ 'NoExistantAction' ],
        };
        sns.AddPermission(args, function(err, data) {
            fmt.msg("AddPermission() - expecting failure (for many reasons)");
            fmt.dump(err, 'Error');
            fmt.dump(data, 'Data');
        });
    }
});
