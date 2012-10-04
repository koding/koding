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

sdb.DeleteAttributes({
    DomainName : 'test',
    ItemName : 'chilts',
    AttributeName : 'username',
    AttributeValue : 'chilts',
}, function(err, data) {
    fmt.msg("Deleting attributes for chilts - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

sdb.DeleteAttributes({
    DomainName : 'test',
    ItemName : 'chilts',
    AttributeName : [ 'url' ],
    AttributeValue : [ 'chilts' ],
    ExpectedName : [ 'url' ],
    ExpectedValue : [ 'blah' ],
}, function(err, data) {
    fmt.msg("Deleting attributes for chilts (conditional) - expecting failure");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
