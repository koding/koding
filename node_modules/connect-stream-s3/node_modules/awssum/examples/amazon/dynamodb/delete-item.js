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
    console.log("\ndeleting user 'pie' - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
