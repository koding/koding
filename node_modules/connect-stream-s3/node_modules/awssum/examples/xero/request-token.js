var inspect = require('eyes').inspector();
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var xeroService = awssum.load('xero/xero');

var env = process.env;
var consumerKey = process.env.XERO_CONSUMER_KEY;
var consumerSecret = process.env.XERO_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var xero = new xeroService.Xero({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});


console.log( 'ConsumerKey :', xero.consumerKey() );
console.log( 'ConsumerSecret :',  xero.consumerSecret() );

xero.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    console.log("\nrequesting token - expecting success");
    if ( err ) {
        inspect(err, 'Error');
        process.exit();
    }

    inspect(data, 'Data');
    console.log( 'If you want to verify this token, visit: '
                 + xero.protocol() + '://' + xero.authorizeHost()
                 + xero.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
