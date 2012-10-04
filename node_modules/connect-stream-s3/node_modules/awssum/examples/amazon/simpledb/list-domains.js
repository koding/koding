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

sdb.ListDomains({}, function(err, data) {
    console.log('\nlist domains - expecting success');
    inspect(err, 'Error');
    inspect(data, 'Data');
});

sdb.ListDomains({ MaxNumberOfDomains : 1 }, function(err, data) {
    console.log('\nlist domains (max=1) - expecting success');
    inspect(err, 'Error');
    inspect(data, 'Data');

    var token;

    if ( err ) {
        console.log('\nNot getting next set of domains due to an error.');
    }
    else {
        token = data.Body.ListDomainsResponse.ListDomainsResult.NextToken;
        sdb.ListDomains({ NextToken : token }, function(err, data) {
            console.log('\nlisting next set of domains (token=' + token + ' ) - expecting success');
            inspect(err, 'Error');
            inspect(data, 'Data');
        });
    }
});
