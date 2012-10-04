var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var DynamoDB = awssum.load('amazon/dynamodb').DynamoDB;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var ddb = new DynamoDB({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', ddb.region() );
fmt.field('EndPoint', ddb.host() );
fmt.field('AccessKeyId', ddb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', ddb.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', ddb.awsAccountId() );

var data1 = {
    TableName : 'test',
    HashKeyValue : {
        'S' : 'chilts',
    },
};

ddb.Query(data1, function(err, data) {
    fmt.msg("querying the test table - expecting failure (needs a HASH,RANGE table, not a HASH table)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var data2 = {
    TableName : 'test-hash-range',
    HashKeyValue : {
        'S' : 'chilts',
    },
};

ddb.Query(data2, function(err, data) {
    fmt.msg("querying the test-hash-range table - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
