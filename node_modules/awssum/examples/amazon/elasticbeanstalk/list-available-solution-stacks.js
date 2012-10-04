var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var ElasticBeanstalk = awssum.load('amazon/elasticbeanstalk').ElasticBeanstalk;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var eb = new ElasticBeanstalk({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region'          : amazon.US_EAST_1,
});

fmt.field('Region', eb.region() );
fmt.field('EndPoint', eb.host() );
fmt.field('AccessKeyId', eb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', eb.secretAccessKey().substr(0, 3) + '...' );

eb.ListAvailableSolutionStacks(function(err, data) {
    fmt.msg("listing available solution stacks - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
