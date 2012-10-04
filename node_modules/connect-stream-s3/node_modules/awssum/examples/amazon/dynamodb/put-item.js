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
    Item : {
        id       : { S : '9bcd1573-00a5-4676-9f9c-9581c8060777' },
        username : { S : 'andychilton' },
        logins   : { N : '0' },
        password : { S : '$2a$10$QfFcIJohati4wvwc9OuFg.IXvsUH6N5ZRmkYxky.5Vh2wGYqvM6Pi' },
    },
};

ddb.PutItem(user1, function(err, data) {
    console.log("\nputting item1 - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

var user2 = {
    TableName : 'test',
    Item : {},
};

ddb.PutItem(user2, function(err, data) {
    console.log("\nputting item2 without a primary key - expecting failure");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

var user3 = {
    TableName : 'test',
    Item : {
        id       : { 'S' : '378ae6b1-eb74-4cef-8766-66f6aaa3b27d' },
        username : { 'S' : 'chilts' },
        logins   : { 'N' : '13' },
        colour   : { 'S' : 'blue' },
        password : { 'S' : '$2a$10$QfFcIJohati4wvwc9OuFg.IXvsUH6N5ZRmkYxky.5Vh2wGYqvM6Pi' },
    },
    Expected : {
        logins   : { Value : { 'N' : '12' } },
    },
    ReturnValues : 'ALL_OLD',
};

ddb.PutItem(user3, function(err, data) {
    console.log("\nputting item3 with an Expected - expecting failure, fails conditional");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
