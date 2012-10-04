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

var items = {
    RequestItems : {
        'test' : {
            Keys : [
                { HashKeyElement : { S : '378ae6b1-eb74-4cef-8766-66f6aaa3b27d' } },
                { HashKeyElement : { S : '9bcd1573-00a5-4676-9f9c-9581c8060777' } },
                { HashKeyElement : { S : '4d297226-881f-4007-9585-403829e44166' } },
            ],
            AttributesToGet : [ 'id', 'username', 'logins', 'inesrted', 'updated' ],
        },
        'test-tweets' : {
            Keys : [
                {
                    HashKeyElement : { S : 'c3808751-b09d-4dd4-a50f-5cc603235958' },
                    RangeKeyElement : { S : '2012-04-01T21:25:19.156Z' },
                },
            ],
        },
    },
};

ddb.BatchGetItems(items, function(err, data) {
    console.log("\ngetting items - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
