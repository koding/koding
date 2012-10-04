var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Swf = awssum.load('amazon/swf').Swf;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var swf = new Swf({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', swf.region() );
fmt.field('EndPoint', swf.host() );
fmt.field('AccessKeyId', swf.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', swf.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', swf.awsAccountId() );

var openExecutions = {
    'Domain' : 'test',
    'StartTimeFilter' :  {
        'oldestDate' : 1325376070,
        'latestDate' : 1356998399,
    },
};
swf.CountOpenWorkflowExecutions(openExecutions, function(err, data) {
    fmt.msg("count open workflow executions - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var closedExecutions = {
    'Domain' : 'test',
};
swf.CountClosedWorkflowExecutions(closedExecutions, function(err, data) {
    fmt.msg("count closed workflow executions - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var pendingActivities = {
    'Domain' : 'test',
    'TaskList' : {
        'name' : 'test'
    },
};
swf.CountPendingActivityTasks(pendingActivities, function(err, data) {
    fmt.msg("count pending activity tasks - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var pendingDecisions = {
    'Domain' : 'test',
    'TaskList' : {
        'name' : 'test'
    },
};
swf.CountPendingDecisionTasks(pendingDecisions, function(err, data) {
    fmt.msg("count pending decision tasks - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
