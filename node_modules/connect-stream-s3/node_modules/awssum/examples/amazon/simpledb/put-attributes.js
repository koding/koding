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

// ---
// user1

var user1Names = [ 'username', 'url' ];
var user1Values = [ 'chilts', 'http://www.chilts.org/blog/' ];

sdb.PutAttributes({
    DomainName : 'test',
    ItemName : 'chilts',
    AttributeName : user1Names,
    AttributeValue : user1Values
}, function(err, data) {
    console.log("\nputting user chilts - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

var user2 = [
    { name : 'username', value : 'andychilton' },
    { name : 'url',      value : 'http://www.chilts.org/blog/' },
    // only replace this value if it already exists
    { name : 'password', value : 'testpass', exists : true, expected : 'testpass' }
];

// ---
// user2

var user2Names = [ 'username', 'url', 'password' ];
var user2Values = [ 'andychilton', 'http://www.chilts.org/blog/', 'testpass' ];

sdb.PutAttributes({
    DomainName : 'test',
    ItemName : 'andychilton',
    AttributeName : user2Names,
    AttributeValue : user2Values,
    ExpectedName : [ 'password' ],
    ExpectedValue : [ 'testpass' ],
}, function(err, data) {
    console.log("\nputting with a conditional - expecting failure");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

// ---
// user3

var user3Names = [ 'username', 'url', 'password' ];
var user3Values = [ 'andychilton', 'http://www.chilts.org/blog/', 'testpass' ];
var user3Replace = [ false, true ];

sdb.PutAttributes({
    DomainName : 'test',
    ItemName : 'replace',
    AttributeName : user3Names,
    AttributeValue : user3Values,
    AttributeReplace : user3Replace,
}, function(err, data) {
    console.log("\nputting a replace - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

// ---
// user4

var user4Names = [ 'username', 'url', 'salt' ];
var user4Values = [ 'chilts', 'http://www.chilts.org/blog/', 'amo3Rie6' ];
var user4ExNames = [ 'username' ];
var user4ExValues = [ 'andychilton' ];

sdb.PutAttributes({
    DomainName : 'test',
    ItemName : 'expected',
    AttributeName : user4Names,
    AttributeValue : user4Values,
    ExpectedName : user4ExNames,
    ExpectedValues : user4ExValues,
}, function(err, data) {
    console.log("\nputting with an expected - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});

// ---
