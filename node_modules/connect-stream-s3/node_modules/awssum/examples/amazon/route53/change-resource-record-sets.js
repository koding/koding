var inspect = require('eyes').inspector();
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var Route53 = awssum.load('amazon/route53').Route53;

var env = process.env;
var accessKeyId = process.env.ACCESS_KEY_ID;
var secretAccessKey = process.env.SECRET_ACCESS_KEY;
var awsAccountId = process.env.AWS_ACCOUNT_ID;

var r53 = new Route53({
    'accessKeyId'     : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    // 'awsAccountId'    : awsAccountId, // optional
    'region'          : amazon.US_EAST_1
});

console.log( 'Region :', r53.region() );
console.log( 'EndPoint :',  r53.host() );
console.log( 'AccessKeyId :', r53.accessKeyId() );
// console.log( 'SecretAccessKey :', r53.secretAccessKey() );
console.log( 'AwsAccountId :', r53.awsAccountId() );

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
    console.log("\nchanging resource record sets - expecting failure (probably need a new callerReference)");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
