var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var DynamoDB = awssum.load('amazon/dynamodb').DynamoDB;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var ddb = new DynamoDB({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

console.log( 'Region :', ddb.region() );
console.log( 'EndPoint :',  ddb.host() );
console.log( 'AccessKeyId :', ddb.accessKeyId() );
// console.log( 'SecretAccessKey :', ddb.secretAccessKey() );
console.log( 'AwsAccountId :', ddb.awsAccountId() );

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
    console.log("\ncreating a table - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
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
    console.log("\ncreating a table - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
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
    console.log("\ncreating a table - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
