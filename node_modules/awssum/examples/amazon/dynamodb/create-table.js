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
    KeySchema : {
        HashKeyElement : {
            AttributeName : "id",
            AttributeType : "S"
        },
    },
    ProvisionedThroughput : {
        ReadCapacityUnits : 5,
        WriteCapacityUnits : 5
    }
};

ddb.CreateTable(data1, function(err, data) {
    fmt.msg("creating a table - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var data2 = {
    TableName : 'test-tweets',
    KeySchema : {
        HashKeyElement : {
            AttributeName : "id",
            AttributeType : "S"
        },
        RangeKeyElement : {
            AttributeName : "inserted",
            AttributeType : "S"
        }
    },
    ProvisionedThroughput : {
        ReadCapacityUnits : 5,
        WriteCapacityUnits : 5
    }
};

ddb.CreateTable(data2, function(err, data) {
    fmt.msg("creating a table - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var data3 = {
    TableName : 'test-to-delete',
    KeySchema : {
        HashKeyElement : {
            AttributeName : "id",
            AttributeType : "S"
        },
    },
    ProvisionedThroughput : {
        ReadCapacityUnits : 5,
        WriteCapacityUnits : 5
    }
};

ddb.CreateTable(data3, function(err, data) {
    fmt.msg("creating a table - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
