var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SimpleDB = awssum.load('amazon/simpledb').SimpleDB;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sdb = new SimpleDB({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', sdb.region() );
console.log( 'EndPoint :',  sdb.host() );
console.log( 'AccessKeyId :', sdb.accessKeyId() );
// console.log( 'SecretAccessKey :', sdb.secretAccessKey() );
console.log( 'AwsAccountId :', sdb.awsAccountId() );

sdb.GetAttributes({ DomainName : 'test', ItemName : 'chilts' }, function(err, data) {
    console.log("\ngetting chilts - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

sdb.GetAttributes({ DomainName : 'test', ItemName : 'andychilton', ConsistentRead : true }, function(err, data) {
    console.log("\ngetting andychilton - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

sdb.GetAttributes({ DomainName : 'test', ItemName : 'replace', ConsistentRead : true }, function(err, data) {
    console.log("\ngetting replace - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

var expected = { DomainName : 'test', ItemName : 'expected', AttributeName : 'username', ConsistentRead : false };
sdb.GetAttributes(expected, function(err, data) {
    console.log("\ngetting expected - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
