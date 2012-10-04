var inspect = require('eyes').inspector();
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var termService = awssum.load('term/term');

var env = process.env;
var consumerKey = process.env.TERM_CONSUMER_KEY;
var consumerSecret = process.env.TERM_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

console.log( 'ConsumerKey :', term.consumerKey() );
console.log( 'ConsumerSecret :',  term.consumerSecret() );

term.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    console.log("\nrequesting token - expecting success");
    if ( err ) {
        inspect(err, 'Error');
        process.exit();
    }

    inspect(data, 'Data');
    console.log( 'If you want to verify this token, visit: '
                 + term.protocol() + '://' + term.authorizeHost()
                 + term.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
