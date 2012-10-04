var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var ImportExport = awssum.load('amazon/importexport').ImportExport;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var ie = new ImportExport({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region'          : amazon.US_EAST_1
});

fmt.field('Region', ie.region() );
fmt.field('EndPoint', ie.host() );
fmt.field('AccessKeyId', ie.accessKeyId().substr(0,3) + '...' );
fmt.field('SecretAccessKey', ie.secretAccessKey().substr(0,3) + '...' );

ie.ListJobs(function(err, data) {
    fmt.msg("listing jobs - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
