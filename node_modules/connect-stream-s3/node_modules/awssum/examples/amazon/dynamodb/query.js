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
    HashKeyValue : {
        'S' : 'chilts',
    },
};

ddb.Query(data1, function(err, data) {
    console.log("\nquerying the test table - expecting failure (needs a HASH,RANGE table, not a HASH table)");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

var data2 = {
    TableName : 'test-hash-range',
    HashKeyValue : {
        'S' : 'chilts',
    },
};

ddb.Query(data2, function(err, data) {
    console.log("\nquerying the test-hash-range table - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
