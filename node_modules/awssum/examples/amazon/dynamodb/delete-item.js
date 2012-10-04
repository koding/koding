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

var user1 = {
    TableName : 'test',
    Key : {
        HashKeyElement : { S : 'd78aa068-d6b2-477d-bc49-1752dbd82c3f' },
    },
    Expected : {
        username : { Value : { S : 'pie' } },
    },
    ReturnValues : 'ALL_OLD',
};

ddb.DeleteItem(user1, function(err, data) {
    fmt.msg("deleting user 'pie' - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
