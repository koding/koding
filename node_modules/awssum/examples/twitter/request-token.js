var fmt = require('fmt');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var Twitter = awssum.load('twitter/twitter').Twitter;

var env            = process.env;
var consumerKey    = env.TWITTER_CONSUMER_KEY;
var consumerSecret = env.TWITTER_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var twitter = new Twitter({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});


fmt.field('ConsumerKey', twitter.consumerKey() );
fmt.field('ConsumerSecret', twitter.consumerSecret() );

twitter.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    fmt.msg("requesting token - expecting success");
    if ( err ) {
        fmt.dump(err, 'Error');
        process.exit();
    }

    fmt.dump(data, 'Data');
    fmt.msg( 'If you want to verify this token, visit: '
                 + twitter.protocol() + '://' + twitter.authorizeHost()
                 + twitter.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
