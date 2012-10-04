var inspect = require('eyes').inspector();
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var xeroService = awssum.load('xero/xero');

var env = process.env;
var consumerKey = process.env.XERO_CONSUMER_KEY;
var consumerSecret = process.env.XERO_CONSUMER_SECRET;
var token = process.env.XERO_TOKEN;
var tokenSecret = process.env.XERO_TOKEN_SECRET;
var verifier = process.env.XERO_VERIFIER;

var xero = new xeroService.Xero({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

xero.setToken(token);
xero.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', xero.consumerKey()    );
console.log( 'ConsumerSecret :', xero.consumerSecret() );
console.log( 'Token          :', xero.token()          );
console.log( 'TokenSecret    :', xero.tokenSecret()    );

commander.prompt('Enter your verification code : ', function(verifier) {
    xero.GetToken({ OAuthVerifier : verifier }, function(err, data) {
        console.log("\ngetting token - expecting success");
        inspect(err, 'Error');
        inspect(data, 'Data');
    });
});
