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
    console.log("\nputting item1 - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
