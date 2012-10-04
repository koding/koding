var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Route53 = awssum.load('amazon/route53').Route53;

var env             = process.env;
var accessKeyId     = env.ACCESS_KEY_ID;
var secretAccessKey = env.SECRET_ACCESS_KEY;
var awsAccountId    = env.AWS_ACCOUNT_ID;

var r53 = new Route53({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
});

fmt.field('Region', r53.region() );
fmt.field('EndPoint', r53.host() );
fmt.field('AccessKeyId', r53.accessKeyId().substr(0, 3) + '...' );
fmt.field('SecretAccessKey', r53.secretAccessKey().substr(0, 3) + '...' );
fmt.field('AwsAccountId', r53.awsAccountId() );

var args = {
    HostedZoneId : '/Z2JA82LCE3D9B2',
    Comment : 'This change does ... blah, blah, blah!',
    Changes : [
        {
            Action : 'DELETE',
            Name : 'www.example.com',
            Type : 'A',
            Ttl : '600',
            ResourceRecords : [
                '192.0.2.1',
            ],
        },
        {
            Action : 'CREATE',
            Name : 'www.example.com',
            Type : 'A',
            Ttl : '300',
            ResourceRecords : [
                '192.0.2.1',
            ],
        },
    ]
};

r53.ChangeResourceRecordSets(args, function(err, data) {
    fmt.msg("changing resource record sets - expecting failure (probably need a new callerReference)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
