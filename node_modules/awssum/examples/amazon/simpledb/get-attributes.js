var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SimpleDB = awssum.load('amazon/simpledb').SimpleDB;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sdb = new SimpleDB({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', sdb.region() );
fmt.field('EndPoint', sdb.host() );
fmt.field('AccessKeyId', sdb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', sdb.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', sdb.awsAccountId() );

sdb.GetAttributes({ DomainName : 'test', ItemName : 'chilts' }, function(err, data) {
    fmt.msg("getting chilts - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sdb.GetAttributes({ DomainName : 'test', ItemName : 'andychilton', ConsistentRead : true }, function(err, data) {
    fmt.msg("getting andychilton - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sdb.GetAttributes({ DomainName : 'test', ItemName : 'replace', ConsistentRead : true }, function(err, data) {
    fmt.msg("getting replace - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var expected = { DomainName : 'test', ItemName : 'expected', AttributeName : 'username', ConsistentRead : false };
sdb.GetAttributes(expected, function(err, data) {
    fmt.msg("getting expected - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
