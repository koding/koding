var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var DynamoDB = awssum.load('amazon/dynamodb').DynamoDB;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var ddb = new DynamoDB({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'awsAccountId' : awsAccountId,
    'region' : amazon.US_EAST_1
});

fmt.field('Region', ddb.region() );
fmt.field('EndPoint', ddb.host() );
fmt.field('AccessKeyId', ddb.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', ddb.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', ddb.awsAccountId() );

ddb.ListTables(function(err, data) {
    if ( err ) {
        fmt.dump(err, 'Error when Listing Tables');
        return;
    }

    // got the tables ok, now just get the first one to describe
    var tableData = {
        TableName : data.Body.TableNames[0],
    };
    ddb.DescribeTable(tableData, function(err, data) {
        fmt.msg("describing the first table - expecting success");
        fmt.dump(err, 'Error');
        fmt.dump(data, 'Data');
    });
});

ddb.DescribeTable({ TableName : 'test-tweets' }, function(err, data) {
    fmt.msg("describing the test-tweets table - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
