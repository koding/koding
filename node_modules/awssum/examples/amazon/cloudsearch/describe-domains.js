var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var CloudSearch = awssum.load('amazon/cloudsearch').CloudSearch;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var cs = new CloudSearch({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
});

fmt.field('Region', cs.region() );
fmt.field('EndPoint', cs.host() );
fmt.field('AccessKeyId', cs.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', cs.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', cs.awsAccountId() );

cs.DescribeDomains(function(err, data) {
    fmt.msg("describing all domains - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

cs.DescribeDomains({ DomainNames : 'hi' }, function(err, data) {
    fmt.msg("describing a (invalid) domain - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

cs.DescribeDomains({ DomainNames : [ 'hi', 'there' ] }, function(err, data) {
    fmt.msg("describing some (invalid) domains - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
