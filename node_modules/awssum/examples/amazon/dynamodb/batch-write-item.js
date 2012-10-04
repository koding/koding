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

// start the data
var data = {
    'RequestItems' : {},
};

// put two items into the test table, and delete one thing
data.RequestItems.test = [];
data.RequestItems.test.push({
    'PutRequest' : {
        'Item' : {
            'id'       : { 'S' : '49eabe78-2ec7-4347-b821-afd5c7ec7853' },
            'username' : { 'S' : 'peeps' },
            'logins'   : { 'N' : '0' },
            'password' : { 'S' : '$2a$10$QfFcIJohati4wvwc9OuFg.IXvsUH6N5ZRmkYxky.5Vh2wGYqvM6Pi' },
        },
    },
});
data.RequestItems.test.push({
    'PutRequest' : {
        'Item' : {
            'id'       : { 'S' : '6f6dc3da-8d7f-45a2-bee6-944fa964fcda' },
            'username' : { 'S' : 'jeremy' },
            'logins'   : { 'N' : '0' },
            'password' : { 'S' : '$2a$10$QfFcIJohati4wvwc9OuFg.IXvsUH6N5ZRmkYxky.5Vh2wGYqvM6Pi' },
        },
    },
});
data.RequestItems.test.push({
    'DeleteRequest' : {
        'Key' : {
            'HashKeyElement' : { 'S' : 'd78aa068-d6b2-477d-bc49-1752dbd82c3f' },
        },
    },
});

ddb.BatchWriteItem(data, function(err, data) {
    fmt.msg("putting data - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
