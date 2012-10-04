var fmt = require('fmt');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var tumblrService = awssum.load('tumblr/tumblr');

var env            = process.env;
var consumerKey    = env.TUMBLR_CONSUMER_KEY;
var consumerSecret = env.TUMBLR_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var tumblr = new tumblrService.Tumblr({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

fmt.field('ConsumerKey', tumblr.consumerKey() );
fmt.field('ConsumerSecret', tumblr.consumerSecret() );

tumblr.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    fmt.msg("requesting token - expecting success");
    if ( err ) {
        fmt.dump(err, 'Error');
        process.exit();
    }

    fmt.dump(data, 'Data');
    fmt.msg( 'If you want to verify this token, visit: '
                 + tumblr.protocol() + '://' + tumblr.authorizeHost()
                 + tumblr.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
