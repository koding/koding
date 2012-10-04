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

sns.DeleteTopic({ TopicArn : 'fakeTopicArn' }, function(err, data) {
    fmt.msg('\nDeleting this topicArn - expecting failure since it doesn\'t exist');
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sns.DeleteTopic({}, function(err, data) {
    fmt.msg('\nDeleting an undefined topicArn - expecting failure since we didn\'t provide a TopicArn');
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

// firstly, re-create this topic (it's idempotent) to get the topicArn
sns.CreateTopic({ Name : 'my-topic' }, function(err, data) {
    fmt.msg('\nCreating (my-topic) - expecting success');
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');

    // now delete it again
    if ( ! err ) {
        var topicArn = data.CreateTopicResponse.CreateTopicResult.TopicArn;
        sns.DeleteTopic({ TopicArn : topicArn }, function(err, data) {
            fmt.msg('\ndeleting topic (my-topic) - expecting success');
            fmt.dump(err, 'Error');
            fmt.dump(data, 'Data');
        });
    }
});
