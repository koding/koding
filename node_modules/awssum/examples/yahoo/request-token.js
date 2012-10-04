var fmt = require('fmt');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var yahooService = awssum.load('yahoo/yahoo');

var env            = process.env;
var consumerKey    = env.YAHOO_CONSUMER_KEY;
var consumerSecret = env.YAHOO_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var yahoo = new yahooService.Yahoo({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

fmt.field('ConsumerKey', yahoo.consumerKey() );
fmt.field('ConsumerSecret', yahoo.consumerSecret() );

yahoo.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    fmt.msg("requesting token - expecting success");
    if ( err ) {
        fmt.dump(err, 'Error');
        process.exit();
    }

    fmt.dump(data, 'Data');
    fmt.msg( 'If you want to verify this token, visit: '
                 + yahoo.protocol() + '://' + yahoo.authorizeHost()
                 + yahoo.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
