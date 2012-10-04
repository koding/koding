var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SimpleDB = awssum.load('amazon/simpledb').SimpleDB;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var sdb = new SimpleDB(accessKeyId, secretAccessKey, awsAccountId, amazon.US_WEST_1);

console.log( 'Region :', sdb.region() );
console.log( 'EndPoint :',  sdb.host() );
console.log( 'AccessKeyId :', sdb.accessKeyId() );
// console.log( 'SecretAccessKey :', sdb.secretAccessKey() );
console.log( 'AwsAccountId :', sdb.awsAccountId() );

// ---
// three users

var items = [ 'the-pie', 'chilts', 'ben' ];
var attributeNames = [
    [ 'favourite-color', 'lucky-number' ],
    [ 'favourite-color', 'lucky-number' ],
    [ 'favourite-color', 'lucky-number' ],
];
var attributeValues = [
    [ 'red',   2 ],
    [ 'green', 3 ],
    [ 'blue',  4 ],
];
var attributeReplaces = [
    [ true, true ],
    [ true, true ],
    [ true, true ],
];

sdb.BatchPutAttributes({
    DomainName       : 'test',
    ItemName         : items,
    AttributeName    : attributeNames,
    AttributeValue   : attributeValues,
    AttributeReplace : attributeReplaces,
}, function(err, data) {
    console.log("\nputting three objects - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
