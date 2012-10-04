var inspect = require('eyes').inspector();
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var yahooService = awssum.load('yahoo/yahoo');

var env = process.env;
var consumerKey = process.env.YAHOO_CONSUMER_KEY;
var consumerSecret = process.env.YAHOO_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var yahoo = new yahooService.Yahoo({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

console.log( 'ConsumerKey :', yahoo.consumerKey() );
console.log( 'ConsumerSecret :',  yahoo.consumerSecret() );

yahoo.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    console.log("\nrequesting token - expecting success");
    if ( err ) {
        inspect(err, 'Error');
        process.exit();
    }

    inspect(data, 'Data');
    console.log( 'If you want to verify this token, visit: '
                 + yahoo.protocol() + '://' + yahoo.authorizeHost()
                 + yahoo.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
