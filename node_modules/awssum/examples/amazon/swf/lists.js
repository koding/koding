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

var args1 = {
    'RegistrationStatus' : 'REGISTERED',
};
swf.ListDomains(args1, function(err, data) {
    fmt.msg("listing all REGISTERED domains - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var args2 = {
    'Domain'             : 'test',
    'RegistrationStatus' : 'REGISTERED',
};
swf.ListActivityTypes(args2, function(err, data) {
    fmt.msg("listing activity types - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var args3 = {
    'Domain' : 'test',
    'StartTimeFilter' : {
        'oldestDate' : 1325376070,
        'latestDate' : 1356998399,
    },
};
swf.ListOpenWorkflowExecutions(args3, function(err, data) {
    fmt.msg("listing open workflow executions - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var args4 = {
    'Domain' : 'test',
    'StartTimeFilter' : {
        'oldestDate' : 1325376070,
        'latestDate' : 1356998399,
    },
};
swf.ListClosedWorkflowExecutions(args4, function(err, data) {
    fmt.msg("listing closed workflow executions - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
