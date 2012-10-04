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
        HashKeyElement : { S : '9bcd1573-00a5-4676-9f9c-9581c8060777' },
    },
    AttributeUpdates : {
        logins   : {
            Value : { N : '1' },
            Action : 'ADD'
        },
        color : {
            Value : { S : 'white' },
            Action : 'PUT'
        },
        organisations : {
            Value : { SS : [ 'PerlMongers', 'Wgtn.JS' ] },
            Action : 'ADD'
        },
        updated : {
            Value : { S : (new Date()).toISOString() },
            Action : 'PUT'
        },
    },
    Expected : {
        username : {
            Value : { S : 'andychilton' },
        },
    },
    ReturnValues : 'ALL_NEW',
};

ddb.UpdateItem(user1, function(err, data) {
    fmt.msg("putting item1 - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
