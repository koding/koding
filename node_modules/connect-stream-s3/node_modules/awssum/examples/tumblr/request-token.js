var inspect = require('eyes').inspector();
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var tumblrService = awssum.load('tumblr/tumblr');

var env = process.env;
var consumerKey = process.env.TUMBLR_CONSUMER_KEY;
var consumerSecret = process.env.TUMBLR_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var tumblr = new tumblrService.Tumblr({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

console.log( 'ConsumerKey :', tumblr.consumerKey() );
console.log( 'ConsumerSecret :',  tumblr.consumerSecret() );

tumblr.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    console.log("\nrequesting token - expecting success");
    if ( err ) {
        inspect(err, 'Error');
        process.exit();
    }

    inspect(data, 'Data');
    console.log( 'If you want to verify this token, visit: '
                 + tumblr.protocol() + '://' + tumblr.authorizeHost()
                 + tumblr.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
