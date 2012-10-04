var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SimpleDB = awssum.load('amazon/simpledb').SimpleDB;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var sdb = new SimpleDB({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', sdb.region() );
fmt.field('EndPoint', sdb.host() );
fmt.field('AccessKeyId', sdb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', sdb.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', sdb.awsAccountId() );

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
    fmt.msg("putting three objects - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
